import React, { useState } from 'react';
import ReactDOM from 'react-dom';

import CssBaseline from '@material-ui/core/CssBaseline';
import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import Typography from '@material-ui/core/Typography';
import SwipeableDrawer from '@material-ui/core/SwipeableDrawer';
import Divider from '@material-ui/core/Divider';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import ListItemIcon from '@material-ui/core/ListItemIcon';
import ListItemText from '@material-ui/core/ListItemText';

import PhotoCameraIcon from '@material-ui/icons/PhotoCamera';
import ShoppingCartIcon from '@material-ui/icons/ShoppingCart';
import BuildIcon from '@material-ui/icons/Build';

const TestComponent = () => {
  const [drawerOpen, setDrawerOpen] = useState(true);

  return <>
    <CssBaseline />
    <SwipeableDrawer open={drawerOpen}>
      <div style={{minWidth: '240px'}}>Hi there</div>
      <Divider />
      <List>
        <ListItem>
          <ListItemIcon><ShoppingCartIcon /></ListItemIcon>
          <ListItemText>Consumables</ListItemText>
        </ListItem>
        <ListItem>
          <ListItemIcon><PhotoCameraIcon /></ListItemIcon>
          <ListItemText>Photo Booth</ListItemText>
        </ListItem>
        <ListItem>
          <ListItemIcon><BuildIcon /></ListItemIcon>
          <ListItemText>Admin Site</ListItemText>
        </ListItem>
      </List>
    </SwipeableDrawer>
    <AppBar position="fixed">
      <Toolbar>
        <Typography variant="h6">Heimdall</Typography>
      </Toolbar>
    </AppBar>
    <div>hello there</div>
  </>;
};

ReactDOM.render(<TestComponent />, document.getElementById("react-container"));
