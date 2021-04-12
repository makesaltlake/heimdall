import { useLocation } from 'react-router-dom';
import qs from 'qs';

export const useQueryParams = () => qs.parse(useLocation().search);

export const withQueryParams = (url, ...paramsObjects) => {
  const params = Object.assign({}, ...paramsObjects);

  if (Object.keys(params).length === 0) {
    return url;
  } else {
    return `${url}?${qs.stringify(params)}`;
  }
};
