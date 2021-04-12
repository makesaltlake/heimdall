import React from 'react';

import { Link } from 'react-router-dom';
import { gql, useQuery } from '@apollo/client';

import { useQueryParams, withQueryParams } from '../helpers/queryParams';
import Loading from '../helpers/Loading';

const QUERY = gql`
  query($areaId: ID, $categoryId: ID, $breadcrumbCategoryIds: [ID!]!) {
    inventoryArea(id: $areaId) {
      id
      name
    }
    inventorySearch(inventoryAreaId: $areaId, inventoryCategoryId: $categoryId) {
      inventoryCategories {
        id
        name
      }
      inventoryItems {
        id
        name
        partNumber
      }
    }
    breadcrumbCategories: inventoryCategories(ids: $breadcrumbCategoryIds) {
      id
      name
    }
  }
`;

const InventoryScreen = () => {
  const queryParams = useQueryParams();
  const { area: areaId = null, category: categoryIds = [] } = queryParams;

  const lastCategoryId = categoryIds.length > 0 ? categoryIds[categoryIds.length - 1] : null;

  const { loading, data: { inventoryArea, inventorySearch: { inventoryCategories, inventoryItems } = {}, breadcrumbCategories } = {} } = useQuery(QUERY, {
    variables: {
      areaId,
      categoryId: lastCategoryId,
      breadcrumbCategoryIds: categoryIds
    }
  });

  if (loading) {
    return <Loading />;
  }

  return <div>
    <h2>{inventoryArea?.name || 'All Areas'}</h2>
    <div>In category:
      <Link to={withQueryParams('/inventory', queryParams, { category: [] })}>All</Link>
      {breadcrumbCategories.map((category, index) => <>
      {" | "}
      <Link to={withQueryParams('/inventory', queryParams, { category: breadcrumbCategories.slice(0, index + 1).map(({ id }) => id) })}>{category.name}</Link>
    </>)}</div>
    {inventoryCategories?.length > 0 && <>
      <h3>Categories</h3>
      <ul>
        {
          inventoryCategories.map(category => (
            <li>
              <Link to={withQueryParams('/inventory', queryParams, { category: categoryIds.concat([category.id]) })}>
                {category.name}
              </Link>
            </li>
          ))
        }
      </ul>
    </>}
    {inventoryItems?.length > 0 && <>
      <h3>Items</h3>
      <ul>
        {
          inventoryItems.map(item => (
            <li>{item.partNumber} {item.name}</li>
          ))
        }
      </ul>
    </>}
  </div>;
};
export default InventoryScreen;
