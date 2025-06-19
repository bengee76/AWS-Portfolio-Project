import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import FortuneCard from '../components/fortuneCard';
import './fortune.css';

function DailyFortune() {
  const [dailyFortune, setDailyFortune] = useState({ text: "", author: "" });
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchDailyFortune = async () => {
      try {
        const response = await fetch('/api/dailyFortune');
        if (!response.ok) {
          throw new Error('Failed to fetch daily fortune');
        }
        const data = await response.json();
        setDailyFortune(data);
      } catch (err) {
        setError(err.message);
      }
    };

    fetchDailyFortune();
  }, []);

  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div>
      <FortuneCard 
        text={dailyFortune.text} 
        author={dailyFortune.author} 
        title="DAILY COOCKIE" 
      />
      <div className="btn-box">
        <Link to="/random">
          <button className="roll-btn fontcolor2">Roll for Fortune</button>
        </Link>
      </div>
    </div>
  );
}

export default DailyFortune;