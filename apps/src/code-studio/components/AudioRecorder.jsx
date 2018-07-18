import React, { PropTypes } from 'react';
import color from "../../util/color";

const styles = {
  buttonRow: {
    display: 'flex',
    flexFlow: 'row',
    justifyContent: 'space-between',
  },
  button: {
    marginRight: 30
  },
  blueButton: {
    background: color.default_blue,
    color: color.white
  }
};

export default class AudioRecorder extends React.Component {
  static propTypes = {
    visible: PropTypes.bool
  };

  state = {
    audioName: 'mysound'
  };

  onNameChange = (event) => {
    this.setState({audioName: event.target.value});
  };

  render() {
    if (this.props.visible) {
      return <div></div>;
    }

    return (
      <div style={styles.buttonRow}>
        <input type="text" placeholder="mysound1.mp3" onChange={this.onNameChange} value={this.state.audioName}></input>
        <span>
          <button
            onClick={this.onStopClick}
            id="stop-record"
            style={{...styles.blueButton, ...styles.button}}
          >
            <i className="fa fa-stop" />
            &nbsp;Stop
          </button>
          <button
            onClick={()=>{}}
            id="cancel-record"
            style={styles.button}
          >
            Cancel
          </button>
        </span>
      </div>
    );
  }
}
