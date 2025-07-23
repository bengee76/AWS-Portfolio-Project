import React from 'react';
import fortuneCookieIcon from '../assets/fortune-cookie.svg';
import './navbar.css';

function Navbar() {
  return (
    <nav className="navbar">
      <div className="left">
        <div className="logobox">
          <img className="logo" src={fortuneCookieIcon} alt="Fortune Cookie" />
        </div>
        <div className="name">
          <h2 className="fontcolor">Fortune Cookie</h2>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;