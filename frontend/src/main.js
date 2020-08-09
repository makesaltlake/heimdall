import React from 'react';
import ReactDOM from 'react-dom';

const TestComponent = () => {
  return <div>
    <div>Hello!</div>
    <div>How are you?</div>
    <div>I am fine.</div>
    <div>(is all my dog will say. He's probably repeated it a thousand times today.)</div>
  </div>;
};

ReactDOM.render(<TestComponent />, document.getElementById("react-container"));
