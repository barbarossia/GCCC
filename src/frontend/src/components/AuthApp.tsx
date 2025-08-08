import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import LoginForm from './LoginForm';
import SignUpForm from './SignUpForm';
import Dashboard from './dashboard/Dashboard';

const AuthApp: React.FC = () => {
  const [currentView, setCurrentView] = useState<'login' | 'signup'>('login');
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className='min-h-screen flex items-center justify-center'>
        <div className='glass-effect rounded-2xl p-8 shadow-2xl'>
          <div className='flex items-center justify-center'>
            <div className='loading-spinner'></div>
            <span className='text-white'>加载中...</span>
          </div>
        </div>
      </div>
    );
  }

  if (user) {
    return <Dashboard />;
  }

  return (
    <div className='min-h-screen flex items-center justify-center p-4'>
      <div className='glass-effect rounded-2xl p-8 shadow-2xl w-full max-w-md'>
        <div className='text-center mb-8'>
          <h1 className='text-3xl font-bold text-white mb-2'>GCCC</h1>
          <p className='text-blue-100'>Global Consensus Community Currency</p>
        </div>

        {currentView === 'login' ? (
          <LoginForm onSwitchToSignUp={() => setCurrentView('signup')} />
        ) : (
          <SignUpForm onSwitchToLogin={() => setCurrentView('login')} />
        )}
      </div>
    </div>
  );
};

export default AuthApp;
