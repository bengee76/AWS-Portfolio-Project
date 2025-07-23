import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import FortuneCard from '../components/fortuneCard';
import './fortune.css';

function RandomFortune() {
  const [fortune, setFortune] = useState({ text: "", author: "" });
  const [error, setError] = useState(null);
  
  const fetchRandomFortune = async () => {
    try {
      const response = await fetch('api/randomFortune');
      if (!response.ok) {
        throw new Error('Failed to fetch random fortune');
      }
      const data = await response.json();
      setFortune(data);
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    fetchRandomFortune();
  }, []);

  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div>
      <FortuneCard 
        text={fortune.text} 
        author={fortune.author} 
        title="RANDOM COOKIE"
      />
        <div className="btn-box">
            <Link to="/">
                <button className="roll-btn fontcolor2">Daily Cookie</button>
            </Link>
            <button className="roll-btn fontcolor2" onClick={fetchRandomFortune}>Roll for Fortune</button>
        </div>
    </div>
  );
}

export default RandomFortune;