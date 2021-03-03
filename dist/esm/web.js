import { WebPlugin } from '@capacitor/core';
import * as Cookie from './cookie';
import * as Request from './request';
export class HttpWeb extends WebPlugin {
  constructor() {
    super();
    /**
     * Perform an Http request given a set of options
     * @param options Options to build the HTTP request
     */
    this.request = async options => Request.request(options);
    /**
     * Perform an Http GET request given a set of options
     * @param options Options to build the HTTP request
     */
    this.get = async options => Request.get(options);
    /**
     * Perform an Http POST request given a set of options
     * @param options Options to build the HTTP request
     */
    this.post = async options => Request.post(options);
    /**
     * Perform an Http PUT request given a set of options
     * @param options Options to build the HTTP request
     */
    this.put = async options => Request.put(options);
    /**
     * Perform an Http PATCH request given a set of options
     * @param options Options to build the HTTP request
     */
    this.patch = async options => Request.patch(options);
    /**
     * Perform an Http DELETE request given a set of options
     * @param options Options to build the HTTP request
     */
    this.del = async options => Request.del(options);
    /**
     * Gets all HttpCookies as a Map
     */
    this.getCookiesMap = async () => {
      const cookies = Cookie.getCookies();
      const output = {};
      for (const cookie of cookies) {
        output[cookie.key] = cookie.value;
      }
      return output;
    };
    /**
     * Get all HttpCookies as an object with the values as an HttpCookie[]
     */
    this.getCookies = async () => {
      const cookies = Cookie.getCookies();
      return { cookies };
    };
    /**
     * Set a cookie
     * @param key The key to set
     * @param value The value to set
     * @param options Optional additional parameters
     */
    this.setCookie = async (key, value, options) =>
      Cookie.setCookie(key, value, options);
    /**
     * Gets all cookie values unless a key is specified, then return only that value
     * @param key The key of the cookie value to get
     */
    this.getCookie = async key => Cookie.getCookie(key);
    /**
     * Deletes a cookie given a key
     * @param key The key of the cookie to delete
     */
    this.deleteCookie = async key => Cookie.deleteCookie(key);
    /**
     * Clears out cookies by setting them to expire immediately
     */
    this.clearCookies = async () => Cookie.clearCookies();
    /**
     * Uploads a file through a POST request
     * @param options TODO
     */
    this.uploadFile = async options => {
      const formData = new FormData();
      formData.append(options.name, options.blob || 'undefined');
      const fetchOptions = Object.assign(Object.assign({}, options), {
        body: formData,
        method: 'POST',
      });
      return this.post(fetchOptions);
    };
    /**
     * Downloads a file
     * @param options TODO
     */
    this.downloadFile = async options => {
      const requestInit = Request.buildRequestInit(
        options,
        options.webFetchExtra,
      );
      const response = await fetch(options.url, requestInit);
      const blob = await response.blob();
      return {
        blob,
      };
    };
  }
}
//# sourceMappingURL=web.js.map
