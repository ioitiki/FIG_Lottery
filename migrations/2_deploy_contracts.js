var FigToken = artifacts.require("./FigToken.sol");

module.exports = function(deployer) {
  deployer.deploy(FigToken);
};
