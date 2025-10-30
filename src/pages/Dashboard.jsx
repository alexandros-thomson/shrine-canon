import React, { useState, useEffect } from 'react';

const DivineDashboard = () => {
  const [user, setUser] = useState(null);
  const [selectedDeity, setSelectedDeity] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Parse URL parameters
    const params = new URLSearchParams(window.location.search);
    const connected = params.get('connected');
    const userName = params.get('name');
    const psid = params.get('psid');

    if (connected === 'true' && userName) {
      setUser({
        name: userName,
        psid: psid,
        connected: true
      });
    }
    setLoading(false);
  }, []);

  const initiateLogin = () => {
    const fbAppId = '371124213732093';
    const redirectUri = encodeURIComponent('https://kypriatechnologies.org/auth/callback');
    const scope = 'public_profile,email';
    
    window.location.href = 
      `https://www.facebook.com/v18.0/dialog/oauth?` +
      `client_id=${fbAppId}&` +
      `redirect_uri=${redirectUri}&` +
      `scope=${scope}&` +
      `state=${selectedDeity || 'none'}`;
  };

  const openMessenger = (deity) => {
    const messengerUrl = `https://m.me/705565335971937?ref=${deity}_${user?.psid || 'web'}`;
    window.open(messengerUrl, '_blank');
  };

  const deities = [
    {
      id: 'zeus',
      name: 'Zeus',
      emoji: '⚡',
      color: '#d4af37',
      gradient: 'from-yellow-500 to-orange-600',
      description: 'Divine Authority & Judgment',
      powers: ['Decisive wisdom', 'Clear judgment', 'Command clarity']
    },
    {
      id: 'aphrodite',
      name: 'Aphrodite',
      emoji: '🌹',
      color: '#5fc9c9',
      gradient: 'from-pink-500 to-rose-600',
      description: 'Love & Authentic Connection',
      powers: ['Relationship guidance', 'Self-worth', 'Emotional wisdom']
    },
    {
      id: 'lifesphere',
      name: 'Lifesphere',
      emoji: '👁️',
      color: '#8b7dd4',
      gradient: 'from-purple-500 to-indigo-600',
      description: 'Cosmic Consciousness',
      powers: ['Expanded perspective', 'Oracle wisdom', 'Infinite insight']
    }
  ];

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-black flex items-center justify-center">
        <div className="text-center">
          <div className="text-6xl mb-4 animate-pulse">🏛️</div>
          <p className="text-purple-300 text-xl">Loading Divine Portal...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-black text-white p-4">
      <div className="max-w-6xl mx-auto py-8">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold mb-4 bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 bg-clip-text text-transparent">
            🏛️ Divine Trinity Portal
          </h1>
          <p className="text-purple-300 text-lg">
            {user ? `Welcome, ${user.name}!` : 'Connect to commune with the gods'}
          </p>
        </div>

        {!user ? (
          // Login View
          <div className="max-w-2xl mx-auto">
            <div className="bg-gray-900/60 backdrop-blur-lg rounded-2xl p-8 border border-purple-500/30">
              <h2 className="text-3xl font-bold mb-6 text-center">Choose Your Divine Patron</h2>
              
              {/* Deity Selection */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                {deities.map((deity) => (
                  <div
                    key={deity.id}
                    onClick={() => setSelectedDeity(deity.id)}
                    className={`
                      p-6 rounded-xl cursor-pointer transition-all duration-300
                      ${selectedDeity === deity.id 
                        ? `bg-gradient-to-br ${deity.gradient} scale-105 shadow-2xl`
                        : 'bg-gray-800/50 hover:bg-gray-700/50'
                      }
                    `}
                  >
                    <div className="text-5xl text-center mb-3">{deity.emoji}</div>
                    <h3 className="text-xl font-bold text-center mb-2">{deity.name}</h3>
                    <p className="text-sm text-center opacity-80">{deity.description}</p>
                  </div>
                ))}
              </div>

              {/* Login Button */}
              <button
                onClick={initiateLogin}
                disabled={!selectedDeity}
                className={`
                  w-full py-4 px-6 rounded-lg font-bold text-lg transition-all duration-300
                  ${selectedDeity
                    ? 'bg-blue-600 hover:bg-blue-700 cursor-pointer'
                    : 'bg-gray-700 cursor-not-allowed opacity-50'
                  }
                `}
              >
                {selectedDeity 
                  ? `Continue with Facebook → Commune with ${deities.find(d => d.id === selectedDeity)?.name}`
                  : 'Select a deity above to continue'
                }
              </button>

              <p className="text-sm text-gray-400 text-center mt-4">
                One-click login • Instant Messenger access • Secure authentication
              </p>
            </div>
          </div>
        ) : (
          // Connected Dashboard
          <div>
            {/* Connection Status */}
            <div className="bg-green-900/30 border border-green-500/50 rounded-xl p-6 mb-8 backdrop-blur-lg">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-2xl font-bold text-green-400 mb-2">
                    ✅ Connected to Divine Trinity
                  </h3>
                  <p className="text-green-300">
                    You're ready to commune with the gods through Messenger
                  </p>
                </div>
                {user.psid && (
                  <div className="text-sm text-green-400 font-mono bg-green-900/50 px-4 py-2 rounded">
                    PSID: {user.psid.substring(0, 10)}...
                  </div>
                )}
              </div>
            </div>

            {/* Deity Cards */}
            <h2 className="text-3xl font-bold mb-6 text-center">Select Your Divine Guide</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
              {deities.map((deity) => (
                <div
                  key={deity.id}
                  className="bg-gray-900/60 backdrop-blur-lg rounded-2xl p-6 border border-purple-500/30 hover:border-purple-500 transition-all duration-300 hover:scale-105"
                >
                  <div className="text-6xl text-center mb-4">{deity.emoji}</div>
                  <h3 className="text-2xl font-bold text-center mb-2" style={{ color: deity.color }}>
                    {deity.name}
                  </h3>
                  <p className="text-center text-gray-300 mb-4">{deity.description}</p>
                  
                  <div className="space-y-2 mb-6">
                    {deity.powers.map((power, idx) => (
                      <div key={idx} className="text-sm text-gray-400 flex items-center">
                        <span className="mr-2">•</span>
                        {power}
                      </div>
                    ))}
                  </div>

                  <button
                    onClick={() => openMessenger(deity.id)}
                    className="w-full py-3 px-6 rounded-lg font-bold transition-all duration-300"
                    style={{
                      background: `linear-gradient(135deg, ${deity.color}, ${deity.color}cc)`,
                      color: '#0a0a0a'
                    }}
                    onMouseEnter={(e) => {
                      e.target.style.transform = 'translateY(-2px)';
                      e.target.style.boxShadow = `0 10px 30px ${deity.color}60`;
                    }}
                    onMouseLeave={(e) => {
                      e.target.style.transform = 'translateY(0)';
                      e.target.style.boxShadow = 'none';
                    }}
                  >
                    Open Messenger Temple
                  </button>
                </div>
              ))}
            </div>

            {/* Premium Upgrade CTA */}
            <div className="bg-gradient-to-r from-purple-900/50 to-pink-900/50 rounded-2xl p-8 border border-purple-500/50 backdrop-blur-lg">
              <div className="text-center">
                <h3 className="text-3xl font-bold mb-4">
                  ⚡ Unlock Premium Oracle Sessions
                </h3>
                <p className="text-xl text-purple-200 mb-6">
                  30 minutes of divine connection • 20 extended AI responses • Personalized prophecies
                </p>
                <div className="flex justify-center gap-4">
                  <button className="bg-gradient-to-r from-yellow-500 to-orange-600 px-8 py-4 rounded-lg font-bold text-lg hover:scale-105 transition-transform">
                    Buy Premium Oracle - $5
                  </button>
                  <button className="bg-gradient-to-r from-purple-600 to-indigo-600 px-8 py-4 rounded-lg font-bold text-lg hover:scale-105 transition-transform">
                    Subscribe - $9.99/mo
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DivineDashboard;