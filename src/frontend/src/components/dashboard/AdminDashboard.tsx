import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';

interface SystemStats {
  totalUsers: number;
  activeUsers: number;
  totalTransactions: number;
  totalVolume: number;
  systemHealth: number;
}

interface AdminMetrics {
  userGrowth: number;
  revenueGrowth: number;
  tokenSupply: number;
  stakingRatio: number;
  nftMinted: number;
}

const AdminDashboard: React.FC = () => {
  const { user, signOut } = useAuth();
  const [loading, setLoading] = useState(true);
  const [systemStats, setSystemStats] = useState<SystemStats | null>(null);
  const [adminMetrics, setAdminMetrics] = useState<AdminMetrics | null>(null);

  useEffect(() => {
    const loadAdminData = async () => {
      // Simulate API call for admin data
      await new Promise(resolve => setTimeout(resolve, 1000));

      setSystemStats({
        totalUsers: 12540,
        activeUsers: 3420,
        totalTransactions: 89650,
        totalVolume: 1245678.9,
        systemHealth: 98.5,
      });

      setAdminMetrics({
        userGrowth: 15.6,
        revenueGrowth: 23.4,
        tokenSupply: 1000000000,
        stakingRatio: 45.8,
        nftMinted: 4567,
      });

      setLoading(false);
    };

    loadAdminData();
  }, []);

  const handleRefresh = async () => {
    setLoading(true);
    await new Promise(resolve => setTimeout(resolve, 500));
    setLoading(false);
  };

  if (!user || user.role !== 'admin') {
    return (
      <div className='min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center'>
        <div className='glass-effect rounded-xl p-8 text-center'>
          <h2 className='text-2xl font-bold text-white mb-4'>访问被拒绝</h2>
          <p className='text-blue-200'>您没有管理员权限访问此页面</p>
        </div>
      </div>
    );
  }

  return (
    <div className='min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-6'>
      <div className='max-w-7xl mx-auto space-y-6'>
        {/* Header */}
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-3xl font-bold text-white'>管理员仪表盘</h1>
            <p className='text-blue-200 mt-2'>系统监控与管理</p>
          </div>
          <div className='flex items-center space-x-3'>
            <button
              onClick={handleRefresh}
              className='px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors flex items-center space-x-2'
            >
              <span>🔄</span>
              <span>刷新</span>
            </button>
            <button
              onClick={signOut}
              className='px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors flex items-center space-x-2'
            >
              <span>🚪</span>
              <span>退出登录</span>
            </button>
          </div>
        </div>

        {/* System Status Cards */}
        <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6'>
          {/* Total Users */}
          <div className='glass-effect rounded-xl p-6 shadow-lg'>
            <div className='flex items-center justify-between mb-4'>
              <div className='w-12 h-12 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 flex items-center justify-center'>
                <span className='text-white font-bold text-xl'>👥</span>
              </div>
              <div className='text-green-400 text-sm'>
                +{adminMetrics?.userGrowth}%
              </div>
            </div>
            <div>
              <h3 className='text-white font-semibold'>总用户数</h3>
              <p className='text-2xl font-bold text-white mt-2'>
                {loading ? '---' : systemStats?.totalUsers.toLocaleString()}
              </p>
              <p className='text-blue-200 text-sm mt-1'>
                活跃:{' '}
                {loading ? '---' : systemStats?.activeUsers.toLocaleString()}
              </p>
            </div>
          </div>

          {/* Total Transactions */}
          <div className='glass-effect rounded-xl p-6 shadow-lg'>
            <div className='flex items-center justify-between mb-4'>
              <div className='w-12 h-12 rounded-full bg-gradient-to-r from-green-500 to-blue-500 flex items-center justify-center'>
                <span className='text-white font-bold text-xl'>💹</span>
              </div>
              <div className='text-green-400 text-sm'>+8.2%</div>
            </div>
            <div>
              <h3 className='text-white font-semibold'>总交易数</h3>
              <p className='text-2xl font-bold text-white mt-2'>
                {loading
                  ? '---'
                  : systemStats?.totalTransactions.toLocaleString()}
              </p>
              <p className='text-blue-200 text-sm mt-1'>今日: 1,247</p>
            </div>
          </div>

          {/* Total Volume */}
          <div className='glass-effect rounded-xl p-6 shadow-lg'>
            <div className='flex items-center justify-between mb-4'>
              <div className='w-12 h-12 rounded-full bg-gradient-to-r from-yellow-500 to-orange-500 flex items-center justify-center'>
                <span className='text-white font-bold text-xl'>💰</span>
              </div>
              <div className='text-green-400 text-sm'>
                +{adminMetrics?.revenueGrowth}%
              </div>
            </div>
            <div>
              <h3 className='text-white font-semibold'>总交易量</h3>
              <p className='text-2xl font-bold text-white mt-2'>
                {loading
                  ? '---'
                  : `$${systemStats?.totalVolume.toLocaleString()}`}
              </p>
              <p className='text-blue-200 text-sm mt-1'>今日: $24,567</p>
            </div>
          </div>

          {/* System Health */}
          <div className='glass-effect rounded-xl p-6 shadow-lg'>
            <div className='flex items-center justify-between mb-4'>
              <div className='w-12 h-12 rounded-full bg-gradient-to-r from-purple-500 to-pink-500 flex items-center justify-center'>
                <span className='text-white font-bold text-xl'>⚡</span>
              </div>
              <div className='text-green-400 text-sm'>健康</div>
            </div>
            <div>
              <h3 className='text-white font-semibold'>系统状态</h3>
              <p className='text-2xl font-bold text-white mt-2'>
                {loading ? '---' : `${systemStats?.systemHealth}%`}
              </p>
              <p className='text-blue-200 text-sm mt-1'>在线节点: 12/12</p>
            </div>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className='grid grid-cols-1 lg:grid-cols-3 gap-6'>
          {/* Left Column - Token Metrics */}
          <div className='space-y-6'>
            {/* Token Supply */}
            <div className='glass-effect rounded-xl p-6 shadow-lg'>
              <h3 className='text-white font-semibold mb-4'>代币供应</h3>
              <div className='space-y-4'>
                <div>
                  <div className='flex justify-between text-sm text-blue-200 mb-2'>
                    <span>总供应量</span>
                    <span>{adminMetrics?.tokenSupply.toLocaleString()}</span>
                  </div>
                  <div className='w-full bg-white/10 rounded-full h-2'>
                    <div className='bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full w-3/4' />
                  </div>
                </div>
                <div>
                  <div className='flex justify-between text-sm text-blue-200 mb-2'>
                    <span>质押比例</span>
                    <span>{adminMetrics?.stakingRatio}%</span>
                  </div>
                  <div className='w-full bg-white/10 rounded-full h-2'>
                    <div
                      className='bg-gradient-to-r from-green-500 to-blue-500 h-2 rounded-full'
                      style={{ width: `${adminMetrics?.stakingRatio}%` }}
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* NFT Stats */}
            <div className='glass-effect rounded-xl p-6 shadow-lg'>
              <h3 className='text-white font-semibold mb-4'>NFT 统计</h3>
              <div className='space-y-3'>
                <div className='flex justify-between'>
                  <span className='text-blue-200'>已铸造</span>
                  <span className='text-white font-medium'>
                    {adminMetrics?.nftMinted.toLocaleString()}
                  </span>
                </div>
                <div className='flex justify-between'>
                  <span className='text-blue-200'>今日铸造</span>
                  <span className='text-white font-medium'>127</span>
                </div>
                <div className='flex justify-between'>
                  <span className='text-blue-200'>活跃交易</span>
                  <span className='text-white font-medium'>1,234</span>
                </div>
              </div>
            </div>
          </div>

          {/* Middle Column - Charts Placeholder */}
          <div className='glass-effect rounded-xl p-6 shadow-lg'>
            <h3 className='text-white font-semibold mb-4'>数据图表</h3>
            <div className='h-64 bg-white/5 rounded-lg flex items-center justify-center'>
              <p className='text-blue-200'>图表组件开发中...</p>
            </div>
          </div>

          {/* Right Column - Admin Actions */}
          <div className='space-y-6'>
            {/* Quick Admin Actions */}
            <div className='glass-effect rounded-xl p-6 shadow-lg'>
              <h3 className='text-white font-semibold mb-4'>管理操作</h3>
              <div className='space-y-3'>
                <button className='w-full px-4 py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors'>
                  用户管理
                </button>
                <button className='w-full px-4 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors'>
                  交易监控
                </button>
                <button className='w-full px-4 py-3 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors'>
                  系统配置
                </button>
                <button className='w-full px-4 py-3 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors'>
                  紧急停止
                </button>
              </div>
            </div>

            {/* System Alerts */}
            <div className='glass-effect rounded-xl p-6 shadow-lg'>
              <h3 className='text-white font-semibold mb-4'>系统警报</h3>
              <div className='space-y-3'>
                <div className='p-3 bg-yellow-500/20 border-l-4 border-yellow-500 rounded'>
                  <p className='text-yellow-300 text-sm'>检测到异常交易活动</p>
                  <p className='text-yellow-200 text-xs mt-1'>5分钟前</p>
                </div>
                <div className='p-3 bg-green-500/20 border-l-4 border-green-500 rounded'>
                  <p className='text-green-300 text-sm'>系统备份完成</p>
                  <p className='text-green-200 text-xs mt-1'>1小时前</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
