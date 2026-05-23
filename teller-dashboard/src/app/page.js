"use client";

import { useState } from 'react';

export default function Dashboard() {
  const [accountId, setAccountId] = useState('10046005');
  const [accountData, setAccountData] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [userRole, setUserRole] = useState('Teller'); // Default Role

  const fetchAccount = async (e) => {
    e.preventDefault();
    setLoading(true); setError(''); setAccountData(null);

    try {
      const response = await fetch(`http://localhost:5000/api/accounts/${accountId}`);
      const json = await response.json();
      if (!response.ok) throw new Error(json.error || 'Failed to fetch account');
      setAccountData(json.data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const updateAccountStatus = async (newStatus) => {
    try {
      const response = await fetch(`http://localhost:5000/api/accounts/update`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${userRole}` // Passing the simulated RACF token
        },
        body: JSON.stringify({ accountId: accountData.accountNumber, newStatus })
      });
      
      const json = await response.json();
      if (!response.ok) throw new Error(json.error);
      
      // If successful, re-fetch the account to prove the change worked
      document.querySelector('.search-form button').click();
    } catch (err) {
      alert(`SYSTEM ALERT:\n${err.message}`);
    }
  };

  return (
    <div className="dashboard-container">
      <header className="header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1>Global Core Banking | Teller Interface</h1>
        <div>
          <label style={{ fontSize: '0.85rem', color: '#666', marginRight: '10px' }}>ACTIVE TERMINAL ROLE:</label>
          <select value={userRole} onChange={(e) => setUserRole(e.target.value)} style={{ padding: '5px' }}>
            <option value="Teller">Teller 042 (Standard)</option>
            <option value="Manager">Manager 081 (Admin)</option>
          </select>
        </div>
      </header>

      <main className="main-content">
        <section className="search-section">
          <h2>Account Inquiry</h2>
          <form onSubmit={fetchAccount} className="search-form">
            <input type="text" value={accountId} onChange={(e) => setAccountId(e.target.value)} placeholder="Enter 8-digit Account ID" pattern="\d{8}" required />
            <button type="submit" disabled={loading}>{loading ? 'Querying...' : 'Retrieve Account'}</button>
          </form>
          {error && <div className="error-badge">{error}</div>}
        </section>

        {accountData && (
          <section className="results-section">
            <div className="card">
              <div className="card-header">
                <h3>{accountData.customerName}</h3>
                <span className={`status-badge ${accountData.accountStatus.toLowerCase()}`}>{accountData.accountStatus}</span>
              </div>
              
              <div className="data-grid">
                <div className="data-group"><label>Account Number</label><p>{accountData.accountNumber}</p></div>
                <div className="data-group"><label>Branch</label><p>{accountData.branchCode}</p></div>
                <div className="data-group"><label>Type</label><p>{accountData.accountType}</p></div>
                <div className="data-group"><label>Last Activity</label><p>{accountData.lastActivityDate}</p></div>
              </div>

              <div className="financials">
                <div className="balance-group"><label>Ledger Balance</label><p className="amount">${accountData.ledgerBalance}</p></div>
                <div className="balance-group highlight"><label>Available Balance</label><p className="amount">${accountData.availableBalance}</p></div>
              </div>

              {/* Administrative Actions Panel */}
              <div style={{ marginTop: '30px', paddingTop: '20px', borderTop: '1px solid #eee' }}>
                <h4 style={{ margin: '0 0 15px 0', color: '#666', textTransform: 'uppercase', fontSize: '0.85rem' }}>Administrative Actions</h4>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <button 
                    onClick={() => updateAccountStatus('FROZEN')} 
                    style={{ background: '#ef4444', color: 'white', padding: '10px 15px', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>
                    Freeze Account
                  </button>
                  <button 
                    onClick={() => updateAccountStatus('ACTIVE')} 
                    style={{ background: '#10b981', color: 'white', padding: '10px 15px', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>
                    Remove Freeze
                  </button>
                </div>
              </div>
            </div>
          </section>
        )}
      </main>
    </div>
  );
}