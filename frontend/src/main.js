import React from 'react';
import ReactDOM from 'react-dom';

import { BrowserRouter as Router, Route, Switch, Redirect } from 'react-router-dom';

import ExternalRedirect from './ExternalRedirect';
import Demo from './demo';

const App = () => {
  return (
    <Router>
      <Switch>
        <Route path="/frontend-demo">
          <Demo />
        </Route>

        {/* Redirect all requests that don't match another route to /admin */}
        <ExternalRedirect to="/admin" />
      </Switch>
    </Router>
  )
};

ReactDOM.render(<App />, document.getElementById("react-container"));
