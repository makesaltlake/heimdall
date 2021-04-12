import { ApolloClient, InMemoryCache } from '@apollo/client';

// TODO: Get rid of the CSRF token stuff - but make 100% certain we're not
// vulnerable to cross-site request forgery attacks by doing so first.
const csrfToken = document.querySelector('meta[name=csrf-token]').getAttribute('content');

export const client = new ApolloClient({
  uri: '/graphql',
  headers: {
    'X-CSRF-Token': csrfToken
  },
  cache: new InMemoryCache(),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'cache-and-network'
    },
    query: {
      fetchPolicy: 'network-only'
    }
  }
});
