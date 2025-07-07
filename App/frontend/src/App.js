import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Navbar from './components/navbar.js';
import RandomFortune from './pages/randomFortune';
import DailyFortune from './pages/dailyFortune';
import './app.css';

function App() {
    return (
        <Router>
        <div className="app">
            <Navbar />
            <div className="center">
                <Routes>
                <Route path="/" element={<DailyFortune />} />
                <Route path="/random" element={<RandomFortune />} />
                </Routes>
            </div>
        </div>
        </Router>
    );
    }

export default App;