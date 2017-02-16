// ==UserScript==
// @name         XMLSWeb
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       Tom T.
// @match        http://njmls.xmlsweb.com/public/p/Listings/0/New/Horizontal*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
    document.addEventListener("click", function(){
        setTimeout(enhance, 1000);
    });
    setTimeout(enhance, 1000);
})();

function enhance () {
    //reduce padding on buttons div to make room for thrid party links
    set_buttons_syle();
    var addrList = document.getElementsByClassName("list_2");
    var boxList = document.getElementsByClassName("inner_box2");

    if (addrList.length) {
        for (var i=0; i < addrList.length; i++) {
            var oAddr = addrList[i];
            //var match_array = oAddr.innerText.match(/Address\s+([^\n]+)\nCity\s+([^\n]+)\nStyle\s+[^\n]\nZip\s+([^\n]+)/gm);
            var match_array = oAddr.innerText.match(/Address\s+([^\r\n]+)\r?\nCity\s+([^\r\n]+)\r?\nStyle\s+([^\r\n]+)\r?\nZip\s+([^\r\n]+)\r?\n/);
            if (match_array) {
                var address = match_array[1];
                var city    = match_array[2];
                var zip     = match_array[4];
                //Zillow
                var zillow_html = get_zillow_html(address, city, zip);
                //NJ MLS
                var mls_id = get_mls_id(boxList[i]);
                //Google Maps
                var google_maps_html = get_google_maps_html(address, city, zip);
                var njmls_html = get_njmls_html(mls_id);
                var container = get_third_party_container(oAddr, address);
                container.innerHTML = zillow_html + ' ' + njmls_html +' ' + google_maps_html;
            }
        }
    }
}

function get_zillow_html (address, city, zip) {
    var link = 'http://www.zillow.com/homes/' + address +' '+ city +' '+ zip +'_rb/';
    var icon = '<img style="width:15px;height:15px;" src="https://usshortcodedirectory.com/wp-content/uploads/2016/03/png-2761"/>';
    return '<a target="zillow" href="' + link + '">' + icon + '</a>';
}

function get_njmls_html (mls_id) {
    var link = 'http://www.njmls.com/listings/index.cfm?action=dsp.info&mlsnum=' + mls_id;
    var icon = '<img style="width:15px;height:15px;" src="http://www.njmls.com/img/2012/app%20icon_njmls.png"/>';
    return '<a target="njmls" href="' + link + '">' + icon + '</a>';
}
function get_google_maps_html( address, city, zip){
    var link = 'http://maps.google.com/?q=' + address +' '+ city +' '+ zip;
    var icon = '<img style="width:15px;height:15px;" src="https://lh3.googleusercontent.com/MOf9Kxxkj7GvyZlTZOnUzuYv0JAweEhlxJX6gslQvbvlhLK5_bSTK6duxY2xfbBsj43H=w300"/>';
    return '<a target="google_maps" href="' + link + '">' + icon + '</a>';
}

function get_mls_id(oHTML) {
    var match_array = oHTML.innerHTML.match(/listingid=.(\d+)/);
    if (match_array) {
        return match_array[1];
    }
    return undefined;
}

//get a container for thind party links relative to listing node
function get_third_party_container(oAddr, address) {
    var elm = document.getElementById(address);
    if (elm) {
        //clear out container node each time
        elm.innerHTML = '';
    } else {
        elm = document.createElement('span');
        elm.id = address;
        insertAfter(elm, oAddr);
    }
    return elm;
}

//insert sibling html element after targetElement
function insertAfter(newElement,targetElement) {
     var parent = targetElement.parentNode;
    if (parent.lastChild == targetElement) {
        parent.appendChild(newElement);
    } else {
         parent.insertBefore(newElement, targetElement.nextSibling);
    }
}

function set_buttons_syle () {
    var buttons = document.getElementsByClassName("buttons");
    if (buttons.length) {
        for (var i=0; i < buttons.length; i++) {
            buttons[i].setAttribute('style', 'padding: 10px 0 0 0');
        }
    }
}
