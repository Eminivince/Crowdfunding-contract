// var expect = require('chai').expect;



const CrowdFunding = artifacts.require("CrowdFunding");

//const zombieNames = ["Zombie 1", "Zombie 2"];

contract("CrowdFunding", (accounts) => {
    let [alice, bob, trent ] = accounts;

    let contractInstance

    beforeEach(async () => {
        contractInstance = await CrowdFunding.new()
    });
    afterEach(async () => {
        contractInstance.destroy(alice)
    });

    //Tests

    it("Should allow user to register", async () => {
        const result = await contractInstance.register({ from: alice });
        //console.log(result.receipt.status);
        const isRegistered = await contractInstance.isRegistered(alice);
        const isNotRegistered = await contractInstance.isRegistered(bob);
        assert.equal(isRegistered, !isNotRegistered)
    })
    it("Further confirms registration by both users", async () => {
        result = await contractInstance.register({ from: alice });
        result1 = await contractInstance.register({ from: bob });
        //console.log(result.receipt.status);
        const isAliceRegistered = await contractInstance.isRegistered(alice);
        const isBobRegistered = await contractInstance.isRegistered(bob);

        assert.equal(isAliceRegistered, isBobRegistered);
    })
    it("Should allow alice to create a fund only if registered", async () =>{
        // Attempt when Not registered...should fail
        const date = new Date;
        const time = date.getTime();  
        const timeToUse = time.toString();

        let unregistered

        try{
            await contractInstance.postRequest("100000000000000000", alice, "School", timeToUse);
        } catch(err){
            unregistered = false;
        }
        assert.equal(unregistered, false);

        //Attempt after Registered...should pass
        await contractInstance.register({ from: alice });
        const isRegistered = await contractInstance.isRegistered(alice);

        let status;

        try{
            const isPostRequest = await contractInstance.postRequest("100000000000000000", alice, "School", timeToUse);
            status = isPostRequest.receipt.status;
        } catch(err){
            console.log(err);
        }
        assert.equal(status, true)
    })
})