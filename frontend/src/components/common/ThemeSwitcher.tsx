import React, { useState, useEffect } from 'react';
import './ThemeSwitcher.css';

const themes = ['purple', 'mocha', 'catppuccin', 'strawberry-matcha'];

export const ThemeSwitcher = () => {
  const [activeTheme, setActiveTheme] = useState(localStorage.getItem('theme') || 'purple');

  useEffect(() => {
    document.body.className = activeTheme;
    localStorage.setItem('theme', activeTheme);
  }, [activeTheme]);

  return (
    <div className="theme-switcher">
      <label htmlFor="theme-select">Theme:</label>
      <select
        id="theme-select"
        value={activeTheme}
        onChange={(e) => setActiveTheme(e.target.value)}
      >
        {themes.map((theme) => (
          <option key={theme} value={theme}>
            {theme}
          </option>
        ))}
      </select>
    </div>
  );
};
