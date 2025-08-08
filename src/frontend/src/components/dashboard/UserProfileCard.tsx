import React, { useState } from 'react';
import { User } from '../../types/auth';

interface UserData {
  username: string;
  level: number;
  vipLevel?: number;
  avatar?: string;
  joinDate?: string;
  totalAssets?: number;
  vipProgress?: number;
  experience?: number;
}

interface UserProfileCardProps {
  user: User | UserData | null;
}

const UserProfileCard: React.FC<UserProfileCardProps> = ({ user }) => {
  const [showProfileMenu, setShowProfileMenu] = useState(false);

  const getVipBadgeColor = (level: number) => {
    if (level >= 10) return '#b9f2ff'; // diamond
    if (level >= 7) return '#ffd700'; // gold
    if (level >= 4) return '#c0c0c0'; // silver
    return '#8b9dc3'; // bronze
  };

  const getVipLevel = (level: number) => {
    if (level >= 10) return 'DIAMOND';
    if (level >= 7) return 'GOLD';
    if (level >= 4) return 'SILVER';
    return 'BRONZE';
  };

  if (!user) {
    return (
      <div className='glass-effect rounded-2xl p-6 shadow-xl'>
        <div className='flex items-center space-x-4'>
          {/* Loading Avatar */}
          <div className='w-20 h-20 rounded-full bg-gradient-to-r from-purple-400 to-pink-400 flex items-center justify-center animate-pulse'>
            <span className='text-2xl font-bold text-white'>...</span>
          </div>

          {/* Loading User Info */}
          <div className='flex-1'>
            <div className='h-6 bg-white/20 rounded animate-pulse mb-2'></div>
            <div className='h-4 bg-white/10 rounded animate-pulse w-3/4'></div>
          </div>
        </div>

        {/* Loading Stats */}
        <div className='grid grid-cols-2 gap-4 mt-6'>
          <div className='text-center'>
            <div className='h-8 bg-white/20 rounded animate-pulse mb-2'></div>
            <div className='h-4 bg-white/10 rounded animate-pulse'></div>
          </div>
          <div className='text-center'>
            <div className='h-8 bg-white/20 rounded animate-pulse mb-2'></div>
            <div className='h-4 bg-white/10 rounded animate-pulse'></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className='glass-effect rounded-2xl p-6 shadow-xl'>
      <div className='flex items-center space-x-4'>
        {/* User Avatar */}
        <div className='relative'>
          <div className='w-20 h-20 rounded-full bg-gradient-to-r from-purple-400 to-pink-400 flex items-center justify-center'>
            {user.avatar ? (
              <img
                src={user.avatar}
                alt={user.username}
                className='w-full h-full rounded-full object-cover'
              />
            ) : (
              <span className='text-2xl font-bold text-white'>
                {user.username?.[0]?.toUpperCase() || 'U'}
              </span>
            )}
          </div>

          {/* VIP Badge */}
          <div
            className='absolute -bottom-1 -right-1 px-2 py-1 rounded-full text-xs font-bold text-black'
            style={{ backgroundColor: getVipBadgeColor(user.level) }}
          >
            {getVipLevel(user.level)}
          </div>
        </div>

        {/* User Info */}
        <div className='flex-1'>
          <div className='flex items-center space-x-2'>
            <h2 className='text-2xl font-bold text-white'>{user.username}</h2>
            {'kycStatus' in user && user.kycStatus === 'verified' && (
              <span className='text-green-400' title='已认证用户'>
                ✅
              </span>
            )}
          </div>

          <div className='grid grid-cols-3 gap-4 mt-2 text-sm'>
            <div>
              <span className='text-blue-200'>等级</span>
              <div className='text-white font-semibold'>{user.level}</div>
            </div>
            <div>
              <span className='text-blue-200'>经验值</span>
              <div className='text-white font-semibold'>
                {user.experience?.toLocaleString() || '0'}
              </div>
            </div>
            <div>
              <span className='text-blue-200'>推荐码</span>
              <div className='text-cyan-300 font-mono'>
                {'referralCode' in user ? user.referralCode : 'N/A'}
              </div>
            </div>
          </div>
        </div>

        {/* Profile Actions */}
        <div className='relative'>
          <button
            className='p-2 hover:bg-white/10 rounded-lg transition-colors'
            onClick={() => setShowProfileMenu(!showProfileMenu)}
          >
            <span className='text-white text-xl'>⚙️</span>
          </button>

          {showProfileMenu && (
            <div className='absolute right-0 top-full mt-2 w-48 glass-effect rounded-lg p-2 z-10'>
              <button className='w-full text-left px-3 py-2 text-white hover:bg-white/10 rounded'>
                📝 编辑资料
              </button>
              <button className='w-full text-left px-3 py-2 text-white hover:bg-white/10 rounded'>
                🔒 安全设置
              </button>
              <button className='w-full text-left px-3 py-2 text-white hover:bg-white/10 rounded'>
                📊 数据统计
              </button>
              <hr className='my-2 border-white/20' />
              <button className='w-full text-left px-3 py-2 text-red-300 hover:bg-red-500/20 rounded'>
                🚪 退出登录
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Level Progress */}
      <div className='mt-4'>
        <div className='flex justify-between text-sm text-blue-200 mb-1'>
          <span>经验值进度</span>
          <span>
            {user.experience || 0} / {(user.level + 1) * 1000}
          </span>
        </div>
        <div className='w-full bg-white/20 rounded-full h-2'>
          <div
            className='bg-gradient-to-r from-blue-400 to-purple-400 h-2 rounded-full transition-all duration-1000'
            style={{
              width: `${Math.min(((user.experience || 0) % 1000) / 10, 100)}%`,
            }}
          />
        </div>
      </div>
    </div>
  );
};

export default UserProfileCard;
