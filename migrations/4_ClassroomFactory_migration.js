const Migrations = artifacts.require("ClassroomFactory");

require('dotenv').config();

var Web3 = require('web3');

module.exports = function(deployer) {
    deployer.deploy(Migrations);
};