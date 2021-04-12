import React from 'react';
import ReactDOM from 'react-dom';

import { BrowserRouter as Router, Route, Switch, Redirect } from 'react-router-dom';

import { client as apolloClient } from './helpers/apollo';
import ExternalRedirect from './ExternalRedirect';
import Demo from './demo';
import { ApolloProvider } from '@apollo/client';
import InventoryScreen from './inventory/InventoryScreen';
import InventoryItemScreen from './inventory/InventoryItemScreen';

const App = () => {
  return (
    <ApolloProvider client={apolloClient}>
      <Router>
        <Switch>
          <Route exact path="/frontend-demo">
            <Demo />
          </Route>
          <Route exact path="/inventory">
            <InventoryScreen />
          </Route>
          <Route exact path="/inventory/items/:itemId">
            <InventoryItemScreen />
          </Route>

          {/* Redirect all requests that don't match another route to /admin */}
          <ExternalRedirect to="/admin" />
        </Switch>
      </Router>
    </ApolloProvider>
  )
};

ReactDOM.render(<App />, document.getElementById("react-container"));
