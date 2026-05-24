"use client";

import { useState } from 'react';

export default function Dashboard() {
  const [accountId, setAccountId] = useState('10046005');
  const [accountData, setAccountData] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [userRole, setUserRole] = useState('Teller'); // Default Role

  const isManager = userRole === 'Manager';

  const pullFromMainframe = async (targetId) => {
    try {
      console.log(`[UI] Fetching fresh data for ${targetId}...`);
      
      const response = await fetch(`/api/accounts/${targetId}?timestamp=${Date.now()}`, {
        cache: 'no-store' 
      });
      
      const json = await response.json();
      if (!response.ok) throw new Error(json.error || 'Failed to fetch account');
      
      console.log(`[UI] Received Status: ${json.data.accountStatus}`);
      setAccountData(json.data);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    setLoading(true); 
    setError(''); 
    setAccountData(null); 
    
    await pullFromMainframe(accountId);
    setLoading(false);
  };

  const updateAccountStatus = async (newStatus) => {
    setLoading(true); 
    try {
      console.log(`[UI] Firing payload to mainframe for status: ${newStatus}`);
      const response = await fetch(`/api/update`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${userRole}` 
        },
        body: JSON.stringify({ accountId: accountData.accountNumber, newStatus })
      });
      
      const json = await response.json();
      if (!response.ok) throw new Error(json.error || 'Mainframe rejected the update payload.');
      
      console.log(`[UI] Mainframe accepted job. Waiting for execution spool...`);
      
      setTimeout(async () => {
        console.log(`[UI] Wait complete. Triggering fresh pull...`);
        await pullFromMainframe(accountData.accountNumber);
        setLoading(false);
      }, 4500);

    } catch (err) {
      alert(`SYSTEM ALERT:\n${err.message}`);
      setLoading(false);
    }
  };

  return (
    <div className="dashboard-container">
      <header className="header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1>Global Core Banking | Teller Interface</h1>
        <div>
          <label style={{ fontSize: '0.85rem', color: '#666', marginRight: '10px' }}>ACTIVE TERMINAL ROLE:</label>
          <select value={userRole} onChange={(e) => setUserRole(e.target.value)} style={{ padding: '5px', fontWeight: 'bold' }}>
            <option value="Teller">Teller 042 (Standard)</option>
            <option value="Manager">Manager 081 (Admin)</option>
          </select>
        </div>
      </header>

      <main className="main-content">
        <section className="search-section">
          <h2>Account Inquiry</h2>
          <form onSubmit={handleSearch} className="search-form">
            <input type="text" value={accountId} onChange={(e) => setAccountId(e.target.value)} placeholder="Enter 8-digit Account ID" pattern="\d{8}" required />
            <button type="submit" disabled={loading}>{loading ? 'Querying Mainframe...' : 'Retrieve Account'}</button>
          </form>
          {error && <div className="error-badge">{error}</div>}
        </section>

        {accountData && (
          <section className="results-section">
            <div className="card">
              <div className="card-header">
                <h3>{accountData.customerName}</h3>
                <span className={`status-badge ${accountData.accountStatus.trim().toLowerCase()}`}>{accountData.accountStatus}</span>
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
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
                  <h4 style={{ margin: 0, color: '#333', textTransform: 'uppercase', fontSize: '0.85rem' }}>Administrative Actions</h4>
                  
                  {/* Contextual User Feedback */}
                  {!isManager && (
                    <span style={{ fontSize: '0.75rem', color: '#ef4444', fontWeight: 'bold', background: '#fee2e2', padding: '3px 8px', borderRadius: '12px' }}>
                      Manager Override Required
                    </span>
                  )}
                </div>

                <div style={{ display: 'flex', gap: '10px' }}>
                  <button 
                    onClick={() => updateAccountStatus('FROZEN')} 
                    disabled={loading || !isManager}
                    style={{ 
                      background: (loading || !isManager) ? '#e5e7eb' : '#ef4444', 
                      color: (loading || !isManager) ? '#9ca3af' : 'white', 
                      padding: '10px 15px', 
                      border: 'none', 
                      borderRadius: '4px', 
                      cursor: (loading || !isManager) ? 'not-allowed' : 'pointer', 
                      fontWeight: 'bold',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px'
                    }}>
                    {!isManager && <span>🔒</span>} Freeze Account
                  </button>
                  <button 
                    onClick={() => updateAccountStatus('ACTIVE')} 
                    disabled={loading || !isManager}
                    style={{ 
                      background: (loading || !isManager) ? '#e5e7eb' : '#10b981', 
                      color: (loading || !isManager) ? '#9ca3af' : 'white', 
                      padding: '10px 15px', 
                      border: 'none', 
                      borderRadius: '4px', 
                      cursor: (loading || !isManager) ? 'not-allowed' : 'pointer', 
                      fontWeight: 'bold',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px'
                    }}>
                    {!isManager && <span>🔒</span>} Remove Freeze
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