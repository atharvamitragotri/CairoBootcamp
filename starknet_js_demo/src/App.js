import './App.css';
import { useState, useEffect } from "react"
import { connect } from "get-starknet"
import { Contract } from "starknet"
import { toBN } from "starknet/dist/utils/number"

// import contractAbi from "./contract_abi.json"
import contractAbi from "./Storage_abi.json"

// const contractAddress = "0x0704ed6b41f5d9dfdc5037c627d53ee52aef0675ed47ba59b57b8152c0144a9e"
const contractAddress = "0x02701e09c6769717c9ca219426d9cec0d59e53f19a30b8635589440fb7626deb"
// tx_hash = "0x07d6b63d1f0a48ee5aafa389fb7aa39ef9869f5b02f881248824b3b5c163e265"

function App() {
  const [provider, setProvider] = useState('')
  const [address, setAddress] = useState('')
  const [retrievedBalance, setRetrievedBalance] = useState('')
  const [isConnected, setIsConnected] = useState(false)


  const connectWallet = async () => {
    try {
      // connect the wallet
      const starknet = await connect()
      await starknet?.enable({ starknetVersion: "v4" })
      // set up the provider
      setProvider(starknet.account)
      // set wallet address
      setAddress(starknet.selectedAddress)
      // set connection flag
      setIsConnected(true)

    }
    catch (error) {
      alert(error.message)
    }
  }

  const setBalanceFunction = async () => {
    try {
      // create a contract object based on the provider, address and abi
      const contract = new Contract(contractAbi, contractAddress, provider)

      // call the increase_balance function
      await contract.set_balance(24)

    }
    catch (error) {
      alert(error.message)
    }
  }

  const getBalanceFunction = async () => {
    try {
      // create a contract object based on the provider, address and abi
      const contract = new Contract(contractAbi, contractAddress, provider)
      // call the function
      const _bal = await contract.get_balance()
      // decode the result
      const _decodedBalance = toBN(_bal.res, 16).toString()
      // display the result
      setRetrievedBalance(_decodedBalance)
    }
    catch (error) {
      alert(error.message)
    }
  }
  return (
    <div className="App">
      <header className="App-header">
        <main className="main">
          <h1 className="title">
            Starknet JS Homework
          </h1>
          {
            isConnected ?
              <button className="connect">{address.slice(0, 5)}...{address.slice(60)}</button> :
              <button className="connect" onClick={() => connectWallet()}>Connect wallet</button>
          }

          <p className="description">
            Homework 11!
          </p>

          <div className="grid">
            <div href="#" className="card">
              <h2>Use Alpha-goerli test net! &rarr;</h2>


              <div className="cardForm">
                {/* <input type="text" className="input" placeholder="Enter Name" onChange={(e) => setName(e.target.value)} /> */}

                <input type="submit" className="button" value="Set Balance  " onClick={() => setBalanceFunction()} />
              </div>

              <hr />

              {/* <p>Insert a wallet address, to retrieve its name.</p> */}
              <div className="cardForm">

                <input type="submit" className="button" value="Get Balance " onClick={() => getBalanceFunction()} />
              </div>
              <p>Balance: {retrievedBalance} ETH</p>
            </div>
          </div>
        </main>
      </header>
    </div>
  );
}

export default App;
