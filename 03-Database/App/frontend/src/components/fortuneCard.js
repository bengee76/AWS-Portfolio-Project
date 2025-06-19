import React from "react";
import "./fortuneCard.css";

function FortuneCard({ text, author, title }) {
  return (
    <section className="fortune-card">
    <div className="daily">{title}</div>
      <div className="box">
          <div className="text fontcolor">{text}</div>
          <div className="bottom-row">
              <div className="author fontcolor">{author}</div>
          </div>
      </div>
    </section>
  );
}
export default FortuneCard;