/*
 * Copyright (C) 2020 Rebecca Cran <rebecca@bsdio.com>.
 *
 */

#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/event_groups.h>

#include <cJSON.h>
#include <esp_system.h>
#include <esp_event.h>
#include <nvs_flash.h>
#include <esp_log.h>

#include <esp_vfs_fat.h>
#include <diskio_wl.h>
#include <esp_vfs.h>

/* Littlevgl specific */
#include "lvgl.h"
#include "lvgl_helpers.h"

#include "clrc663.h"
#include "iso14443.h"
#include "mifare_classic.h"
#include "network.h"
#include "tag.h"

static const char* TAG = "heimdall";

#define LV_TICK_PERIOD_MS 1

const int RFID_CS_GPIO_PIN = 32;
const int CAM_CS_GPIO_PIN = 15;

extern char *heimdall_host;
extern char *reader_api_key;
extern char *writer_api_key;

char *tag_key = NULL;

char *org_name = NULL;

extern char *wifi_ssid;
extern char *wifi_password;


static void heimdall_get_param(nvs_handle_t nvs, char *name, char **value)
{
    size_t required_len;

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, NULL, &required_len));

    *value = malloc(required_len);
    assert(value != NULL);

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, *value, &required_len));
}

/*****************************************
 *
 * Adapted from https://github.com/lvgl/lv_port_esp32/blob/master/main/main.c
 *
 *****************************************/

static void create_demo_application(void);

static void lv_tick_task(void *arg) {
    (void) arg;

    lv_tick_inc(LV_TICK_PERIOD_MS);
}

/* Creates a semaphore to handle concurrent call to lvgl stuff
 * If you wish to call *any* lvgl function from other threads/tasks
 * you should lock on the very same semaphore! */
SemaphoreHandle_t xGuiSemaphore;

static void guiTask(void *pvParameter)
{
    (void) pvParameter;
    xGuiSemaphore = xSemaphoreCreateMutex();

    lv_init();

    /* Initialize SPI or I2C bus used by the drivers */
    lvgl_driver_init();

    /* Use double buffered when not working with monochrome displays */
    static lv_color_t buf1[DISP_BUF_SIZE];
    static lv_color_t buf2[DISP_BUF_SIZE];

    static lv_disp_buf_t disp_buf;
    uint32_t size_in_px = DISP_BUF_SIZE;

    /* Initialize the working buffer */
    lv_disp_buf_init(&disp_buf, buf1, buf2, size_in_px);

    lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);
    disp_drv.flush_cb = disp_driver_flush;

    disp_drv.buffer = &disp_buf;
    lv_disp_drv_register(&disp_drv);

    /* Create and start a periodic timer interrupt to call lv_tick_inc */
    const esp_timer_create_args_t periodic_timer_args = {
        .callback = &lv_tick_task,
        .name = "periodic_gui"
    };
    esp_timer_handle_t periodic_timer;
    ESP_ERROR_CHECK(esp_timer_create(&periodic_timer_args, &periodic_timer));
    ESP_ERROR_CHECK(esp_timer_start_periodic(periodic_timer, LV_TICK_PERIOD_MS * 1000));

    /* Create the demo application */
    create_demo_application();

    while (1) {
        /* Delay 1 tick (assumes FreeRTOS tick is 10ms */
        vTaskDelay(pdMS_TO_TICKS(10));

        /* Try to take the semaphore, call lvgl related function on success */
        if (pdTRUE == xSemaphoreTake(xGuiSemaphore, portMAX_DELAY)) {
            lv_task_handler();
            xSemaphoreGive(xGuiSemaphore);
       }
    }

    /* A task should NEVER return */
    vTaskDelete(NULL);
}

lv_obj_t *card_uid_lbl;
lv_obj_t *status_lbl;
lv_obj_t *card_owner_lbl;

static void create_demo_application(void)
{
    /* Get the current screen  */
    lv_obj_t * scr = lv_disp_get_scr_act(NULL);

    /* Create a Label on the currently active screen */
    lv_obj_t *welcome_lbl = lv_label_create(scr, NULL);
    status_lbl =  lv_label_create(scr, NULL);
    card_uid_lbl = lv_label_create(scr, NULL);
    card_owner_lbl = lv_label_create(scr, NULL);

    char *txt = malloc(128);
    snprintf(txt, 128, "Welcome to %s's\nRFID Card Writer Application.", org_name);

    lv_label_set_text(status_lbl, "Initializing...");
    lv_label_set_text(card_uid_lbl, "");
    lv_label_set_text(card_owner_lbl, "");

    lv_label_set_text(welcome_lbl, txt);


    /* Align the Label to the center
     * NULL means align on parent (which is the screen now)
     * 0, 0 at the end means an x, y offset after alignment */

    lv_obj_align(welcome_lbl, NULL, LV_ALIGN_IN_TOP_MID, 0, 0);
    lv_obj_align(status_lbl, NULL, LV_ALIGN_IN_LEFT_MID, 0, -40);
    lv_obj_align(card_uid_lbl, NULL, LV_ALIGN_IN_LEFT_MID, 20, 10);
    lv_obj_align(card_owner_lbl, NULL, LV_ALIGN_IN_LEFT_MID, 20, 80);

    free(txt);
}

void welcome_text(void)
{
    lv_label_set_text(status_lbl, "Please swipe new tag to program.");
    lv_label_set_text(card_uid_lbl, "Card UID: ");
    lv_label_set_text(card_owner_lbl, "Name: ");
}

void update_uuid_lbl(const char *new_uuid)
{
    char lbl_txt[128];
    char *uu;

    char *last_chars;

    uu = calloc(strlen(new_uuid) + 1, 1);

    memcpy(uu, new_uuid, strlen(new_uuid));

    last_chars = strrchr(uu, '-');
    if (last_chars != 0) {
        last_chars[0] = '\0';
        last_chars++;
    }

    sprintf(lbl_txt, "Card UUID:\n%s-\n%s", uu, last_chars);

    lv_label_set_text(card_uid_lbl, lbl_txt);

    free(uu);
}

void update_name_lbl(const char *txt, bool success)
{
    char lbl_txt[128];

    if (success) {
        sprintf(lbl_txt, "Name: %s", txt);
    }
    else
    {
        sprintf(lbl_txt, "Error: %s", txt);
    }

    lv_label_set_text(card_owner_lbl, lbl_txt);
}

void update_status_lbl(const char *txt)
{
    lv_label_set_text(status_lbl, txt);
}

extern EventGroupHandle_t httpEventGroup;

void app_main(void)
{
    esp_err_t ret;
    nvs_handle_t nvs;
    size_t required_len;

    esp_log_level_set("wifi", ESP_LOG_WARN);

    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NOT_FOUND) {
        ESP_ERROR_CHECK(ret);
    }

    ESP_ERROR_CHECK(nvs_open("heimdall", NVS_READWRITE, &nvs));

    heimdall_get_param(nvs, "org_name", &org_name);
    heimdall_get_param(nvs, "wifi_ssid", &wifi_ssid);
    heimdall_get_param(nvs, "wifi_password", &wifi_password);
    heimdall_get_param(nvs, "heimdall_host", &heimdall_host);
    heimdall_get_param(nvs, "reader_api_key", &reader_api_key);
    heimdall_get_param(nvs, "writer_api_key", &writer_api_key);

    ESP_ERROR_CHECK(nvs_get_blob(nvs, "tag_key", NULL, &required_len));

    tag_key = malloc(required_len + 1);
    assert(tag_key != NULL);

    ESP_ERROR_CHECK(nvs_get_blob(nvs, "tag_key", tag_key, &required_len));
    tag_key[required_len] = 0;

    nvs_close(nvs);

    heimdall_setup_wifi(wifi_ssid, wifi_password);

    httpEventGroup = xEventGroupCreate();

    /* If you want to use a task to create the graphic, you NEED to create a Pinned task
     * Otherwise there can be problem such as memory corruption and so on.
     * NOTE: When not using Wi-Fi nor Bluetooth you can pin the guiTask to core 0 */
    xTaskCreatePinnedToCore(guiTask, "gui", 4096*2, NULL, 0, NULL, 1);

    BaseType_t rtret;
    rtret = xTaskCreate(&tag_writer, "tag_writer", 4096, NULL, 5, NULL);
    if (rtret != pdPASS)
    {
        ESP_LOGE(TAG, "Failed to create tag reader thread: %d", rtret);
        assert(0);
    }
}
