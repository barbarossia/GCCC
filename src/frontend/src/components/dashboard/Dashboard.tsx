import React from 'react';
import { useAuth } from '../../contexts/AuthContext';
import UserDashboard from './UserDashboard';
import AdminDashboard from './AdminDashboard';

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  // Show loading state if user data is not yet loaded
  if (!user) {
    return (
      <div className='min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center'>
        <div className='glass-effect rounded-xl p-8 text-center'>
          <div className='animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-4'></div>
          <p className='text-white'>加载中...</p>
        </div>
      </div>
    );
  }

  // Route to appropriate dashboard based on user role
  if (user.role === 'admin') {
    return <AdminDashboard />;
  }

  // Default to user dashboard
  return <UserDashboard />;
};

export default Dashboard;
