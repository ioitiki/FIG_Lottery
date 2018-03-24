import React from 'react';
import ReactDOM from 'react-dom';
import Web3 from 'web3';
import TruffleContract from 'truffle-contract';
import FigToken from '../../build/contracts/FigToken.json';
import 'bootstrap/dist/css/bootstrap.css';

class App extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      account: '0x0',
      bets: [],
      hasBet: false,
      loading: true,
      betting: false,
    };

    if (typeof web3 != 'undefined') {
      this.web3Provider = web3.currentProvider;
    } else {
      this.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    };

    this.web3 = new Web3(this.web3Provider);

    this.fig = TruffleContract(FigToken);
    this.fig.setProvider(this.web3Provider);

    this.bet = this.bet.bind(this);
    this.watchEvents = this.watchEvents.bind(this);
  };

  componentDidMount() {
    // TODO: Refactor with promise chain
    this.web3.eth.getCoinbase((err, account) => {
      this.setState({ account })
      this.fig.deployed().then((figInstance) => {
        this.figInstance = figInstance
        this.watchEvents()
        this.figInstance.betsCount().then((betsCount) => {
          for (var i = 1; i <= betsCount; i++) {
            this.figInstance.bets(i).then((bet) => {
              const bets = [...this.state.bets]
              bets.push({
                id: bet[0],
                name: bet[1],
                voteCount: bet[2]
              });
              this.setState({ bets: bets })
            });
          }
        })
        this.figInstance.voters(this.state.account).then((hasVoted) => {
          this.setState({ hasVoted, loading: false })
        })
      })
    })
  };

  watchEvents() {
    // TODO: trigger event when vote is counted, not when component renders
    this.figInstance.votedEvent({}, {
      fromBlock: 0,
      toBlock: 'latest'
    }).watch((error, event) => {
      this.setState({ voting: false })
    })
  }

  bet(betId) {
    this.setState({ voting: true })
    this.figInstance.vote(betId, { from: this.state.account }).then((result) =>
      this.setState({ hasVoted: true })
    )
  };

  render() {
    return (
      <div class='row'>
        <div class='col-lg-12 text-center' >
          <h1>Election Results</h1>
          <br/>
          { this.state.loading || this.state.voting
            ? <p class='text-center'>Loading...</p>
            : <Content
                account={this.state.account}
                bets={this.state.bets}
                hasVoted={this.state.hasVoted}
                bet={this.bet} />
          }
        </div>
      </div>
    )
  }
};

ReactDOM.render(
   <App />,
   document.querySelector('#root')
);
