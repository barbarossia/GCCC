import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const Dashboard: React.FC = () => {
  const { user, signOut } = useAuth();

  if (!user) return null;

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        <div className="glass-effect rounded-2xl p-8 shadow-2xl">
          <div className="flex justify-between items-center mb-8">
            <h1 className="text-2xl font-bold text-white">
              欢迎回来, {user.username}
            </h1>
            <button
              onClick={signOut}
              className="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors"
            >
              退出登录
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="glass-effect rounded-lg p-6">
              <h3 className="text-lg font-medium text-white mb-2">个人信息</h3>
              <div className="space-y-2 text-blue-100">
                <p>邮箱: {user.email}</p>
                <p>用户名: {user.username}</p>
                <p>角色: {user.role === 'admin' ? '管理员' : '普通用户'}</p>
                <p>等级: {user.level}</p>
              </div>
            </div>

            <div className="glass-effect rounded-lg p-6">
              <h3 className="text-lg font-medium text-white mb-2">经验值</h3>
              <div className="space-y-2 text-blue-100">
                <p>当前经验: {user.experience}</p>
                <p>KYC状态: {user.kycStatus}</p>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-blue-600 h-2 rounded-full"
                    style={{ width: `${(user.experience % 1000) / 10}%` }}
                  ></div>
                </div>
              </div>
            </div>

            <div className="glass-effect rounded-lg p-6">
              <h3 className="text-lg font-medium text-white mb-2">推荐系统</h3>
              <div className="space-y-2 text-blue-100">
                <p>推荐码: {user.referralCode}</p>
                <p>总推荐数: {user.totalReferrals}</p>
                <p>活跃推荐: {user.activeReferrals}</p>
              </div>
            </div>

            <div className="glass-effect rounded-lg p-6 md:col-span-2 lg:col-span-3">
              <h3 className="text-lg font-medium text-white mb-2">账户信息</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-blue-100">
                <p>注册时间: {user.createdAt.toLocaleDateString()}</p>
                <p>最后登录: {user.lastLoginAt?.toLocaleString()}</p>
                {user.walletAddress && (
                  <p className="md:col-span-2">钱包地址: {user.walletAddress}</p>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
