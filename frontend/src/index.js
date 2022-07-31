import React from 'react';
import ReactDOM from 'react-dom/client';
ethers = require('ethers')
import './index.css';


async function connect() {
    if (typeof window.ethereum !== 'undefined') {
        await window.ethereum.request({methods: "eth_requestAccounts"})
        document.getElementById("btn-connect").innerHTML = "Connected!"
    }
}