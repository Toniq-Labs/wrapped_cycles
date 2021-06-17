import { Actor, HttpAgent, Principal } from "@dfinity/agent";  
import wtcIDL from './wtc.did.js';
import minterIDL from './minter.did.js';
//Helpers
const isHex = (h) => {
  var regexp = /^[0-9a-fA-F]+$/;
  return regexp.test(h);
};
const constructUser = (u) => {
  console.log(isHex(u));
  if (isHex(u) && u.length == 64) {
    return { 'address' : u };
  } else {
    return { 'principal' : Principal.fromText(u) };
  };
};
//Initiates the API
var 
WTCCANISTER = "5ymop-yyaaa-aaaah-qaa4q-cai", 
AGENT= new HttpAgent({host : "https://boundary.ic0.app/"}),
MINTER = Actor.createActor(minterIDL, {agent : AGENT, canisterId : "57ni3-vaaaa-aaaah-qaa4a-cai"}),
RAW = Actor.createActor(wtcIDL, {agent : AGENT, canisterId : WTCCANISTER});


const API = {
  cycles : function() {
    return new Promise((resolve, reject) => {
      RAW.availableCycles().then(r => {
        resolve(r);
      }).catch(e => {
        reject(e);
      });
    });
  },
  supply : function() {
    return new Promise((resolve, reject) => {
      RAW.supply("0").then(r => {
        if (typeof r.ok != 'undefined') resolve(r.ok)
        else if (typeof r.err != 'undefined') reject(r.err)
        else reject(r);
      }).catch(e => {
        reject(e);
      });
    });
  },
  metadata : function() {
    return new Promise((resolve, reject) => {
      RAW.metadata("0").then(r => {
        if (typeof r.ok != 'undefined') resolve(r.ok.fungible)
        else if (typeof r.err != 'undefined') reject(r.err)
        else reject(r);
      }).catch(e => {
        reject(e);
      });
    });
  },
  balance : function(u) {
    return new Promise((resolve, reject) => {
      RAW.balance({'user' : constructUser(u), 'token' : "0"}).then(r => {
        if (typeof r.ok != 'undefined') resolve(r.ok)
        else if (typeof r.err != 'undefined') reject(r.err)
        else reject(r);
      }).catch(e => {
        reject(e);
      });
    });
  },
  extensions : function(u) {
    return new Promise((resolve, reject) => {
      RAW.extensions().then(r => {
        resolve(r);
      }).catch(e => {
        reject(e);
      });
    });
  },
  fee : function(u) {
    return new Promise((resolve, reject) => {
      RAW.fee().then(r => {
        resolve(r);
      }).catch(e => {
        reject(e);
      });
    });
  },
  threshold : function(u) {
    return new Promise((resolve, reject) => {
      RAW.minCyclesThreshold().then(r => {
        resolve(r);
      }).catch(e => {
        reject(e);
      });
    });
  },
  raw : RAW,
  minter : MINTER,
}
window.Principal = Principal;
window._wtcapi = API;
export {API};