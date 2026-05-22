"use client";

import { useState } from 'react';

export default function Dashboard() {
  const [accountId, setAccountId] = useState('10045992');
  const [accountData, setAccountData] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const fetchAccount = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setAccountData(null);

    try {
      // Hit the Docker container API running on port 5000
      const response = await fetch(`http://localhost:5000/api/accounts/${accountId}`);
      const json = await response.json();

      if (!response.ok) {
        throw new Error(json.error || 'Failed to fetch account data');
      }

      setAccountData(json.data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="dashboard-container">
      <header className="header">
        <h1>Global Core Banking | Teller Interface</h1>
      </header>

      <main className="main-content">
        <section className="search-section">
          <h2>Account Inquiry</h2>
          <form onSubmit={fetchAccount} className="search-form">
            <input
              type="text"
              value={accountId}
              onChange={(e) => setAccountId(e.target.value)}
              placeholder="Enter 8-digit Account ID"
              pattern="\d{8}"
              title="Must be exactly 8 digits"
              required
            />
            <button type="submit" disabled={loading}>
              {loading ? 'Querying Legacy Core...' : 'Retrieve Account'}
            </button>
          </form>
          {error && <div className="error-badge">{error}</div>}
        </section>

        {accountData && (
          <section className="results-section">
            <div className="card">
              <div className="card-header">
                <h3>{accountData.customerName}</h3>
                <span className={`status-badge ${accountData.accountStatus.toLowerCase()}`}>
                  {accountData.accountStatus}
                </span>
              </div>
              
              <div className="data-grid">
                <div className="data-group">
                  <label>Account Number</label>
                  <p>{accountData.accountNumber}</p>
                </div>
                <div className="data-group">
                  <label>Branch Code</label>
                  <p>{accountData.branchCode}</p>
                </div>
                <div className="data-group">
                  <label>Type</label>
                  <p>{accountData.accountType}</p>
                </div>
                <div className="data-group">
                  <label>Last Activity</label>
                  <p>{accountData.lastActivityDate}</p>
                </div>
              </div>

              <div className="financials">
                <div className="balance-group">
                  <label>Ledger Balance</label>
                  <p className="amount">${accountData.ledgerBalance}</p>
                </div>
                <div className="balance-group highlight">
                  <label>Available Balance</label>
                  <p className="amount">${accountData.availableBalance}</p>
                </div>
              </div>
            </div>
          </section>
        )}
      </main>
    </div>
  );
}