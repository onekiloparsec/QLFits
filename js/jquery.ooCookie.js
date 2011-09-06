/**
 * Ojbect Oriented Javascript Cookies
 *
 * Copyright (c) 2009 Dominique Kimbell
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 */
 
 /**
 * Instantiate a cookie object and assign values.
 * @example var c = new cookie();
 *
 * @desc Set the value of a cookie.
 * @example c.field1 = value1;
            c.field2 = value2;
 * @desc Create a cookie with all available options.			
 * @example cookie.set({ expires: 7, path: '/', domain: 'jquery.com', secure: true });
 
 * @desc Create a session cookie.
 * @example cookie.set();
 
 * @desc Delete a cookie by passing null as value. Keep in mind that you have to use the same path and domain
 *       used when the cookie was set.
 * @example cookie.set(null);
 * 
 * @param Object options An object literal containing key/value pairs to provide optional cookie attributes.
 * @option Number|Date expires Either an integer specifying the expiration date from now on in days or a Date object.
 *                             If a negative value is specified (e.g. a date in the past), the cookie will be deleted.
 *                             If set to null or omitted, the cookie will be a session cookie and will not be retained
 *                             when the the browser exits.
 * @option String path The value of the path atribute of the cookie (default: path of page that created the cookie).
 * @option String domain The value of the domain attribute of the cookie (default: domain of page that created the cookie).
 * @option Boolean secure If true, the secure attribute of the cookie will be set and the cookie transmission will
 *                        require a secure protocol (like HTTPS).
 * @type Object
 */

/**
 * Get the value of a cookie.
 *
 * @desc Get the value of a cookie.
 * @example c.get().field;
 *
 * @optional set/get name of cookie. 
 * 		Default: cookie****... (x = digit);
 * @desc set/get cookie name syntax: 
 * @example c.cookieID = "cookieName" !Important! 'cookieID' is reserved word!
 * @type String
 */
 
jQuery.cookie = function(){
	var url = location.href;
	var filter = ":/.%-_", id = ''; ID = 0;
	for(var ch in url) if (filter.indexOf(ch) == -1) id += ch;
	for(var ch in id) ID += ch.charCodeAt();
	this.cookieID = "cookie"+ID;

	this.set = function(options){
		var cookieContent = '';
		var filterProperties = {"cookieID":0,"set":1,"get":2};
		options = options || {};
		for(var property in this){
			if(!(property in filterProperties)){
				if (this[property] === null) this[property] = '';
				cookieContent += (property) + ':' + (this[property]) + ',';
			}
		}
		cookieContent = cookieContent.substring(0,cookieContent.length-1);
		var expires = '';
		if (options.expires && (typeof options.expires == 'number' || options.expires.toUTCString)) {
			var date;
			if (typeof options.expires == 'number') {
				date = new Date();
				date.setTime(date.getTime() + (options.expires * 24 * 60 * 60 * 1000));
			} else {
				date = options.expires;
			}
			expires = '; expires=' + date.toUTCString(); // use expires attribute, max-age is not supported by IE
		}
		// CAUTION: Needed to parenthesize options.path and options.domain
		// in the following expressions, otherwise they evaluate to undefined
		// in the packed version for some reason...
		var path = options.path ? '; path=' + (options.path) : '';
		var domain = options.domain ? '; domain=' + (options.domain) : '';
		var secure = options.secure ? '; secure' : '';
		document.cookie = [this.cookieID, '=', cookieContent, expires, '; path=/', domain, secure].join('');
		return true;
	};

	this.get = function(){
		var cookieValue = '';
		if (document.cookie && document.cookie != '') {
			var cookies = document.cookie.split(';');
			for (var i = 0; i < cookies.length; i++) {
				var cookie = jQuery.trim(cookies[i]);
				// Does this cookie string begin with the name we want?
				if (cookie.substring(0, this.cookieID.length + 1) == (this.cookieID + '=')) {
					cookieValue = decodeURIComponent(cookie.substring(this.cookieID.length + 1));
					break;
				}
			}
			var properties = cookieValue.split(',');
			for(var i = 0; i<properties.length;i++){
				var property = properties[i].split(':');
				this[property[0]] = property[1];
			}
		}
		return true;
	};
	return this;
};