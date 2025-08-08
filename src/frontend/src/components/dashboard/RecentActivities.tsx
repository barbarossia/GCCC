import React from 'react';

interface RecentActivity {
  id: string;
  type: 'vote' | 'stake' | 'trade' | 'mint' | 'claim' | 'transfer';
  description: string;
  amount?: number;
  token?: string;
  timestamp: Date;
  status: 'success' | 'pending' | 'failed';
}

interface RecentActivitiesProps {
  activities: RecentActivity[];
  loading: boolean;
}

const RecentActivities: React.FC<RecentActivitiesProps> = ({
  activities,
  loading,
}) => {
  const getActivityIcon = (type: RecentActivity['type']) => {
    const icons = {
      vote: '🗳️',
      stake: '🔒',
      trade: '💹',
      mint: '🔨',
      claim: '🎁',
      transfer: '💸',
    };
    return icons[type];
  };

  const getActivityColor = (type: RecentActivity['type']) => {
    const colors = {
      vote: 'text-blue-400',
      stake: 'text-green-400',
      trade: 'text-purple-400',
      mint: 'text-yellow-400',
      claim: 'text-pink-400',
      transfer: 'text-orange-400',
    };
    return colors[type];
  };

  const getStatusColor = (status: RecentActivity['status']) => {
    const colors = {
      success: 'text-green-400',
      pending: 'text-yellow-400',
      failed: 'text-red-400',
    };
    return colors[status];
  };

  const getStatusText = (status: RecentActivity['status']) => {
    const texts = {
      success: '成功',
      pending: '处理中',
      failed: '失败',
    };
    return texts[status];
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) return '刚刚';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}分钟前`;
    if (diffInSeconds < 86400)
      return `${Math.floor(diffInSeconds / 3600)}小时前`;
    return `${Math.floor(diffInSeconds / 86400)}天前`;
  };

  return (
    <div className='glass-effect rounded-xl p-6 shadow-lg'>
      <div className='flex items-center justify-between mb-4'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 rounded-full bg-gradient-to-r from-green-500 to-blue-500 flex items-center justify-center'>
            <span className='text-white font-bold'>📊</span>
          </div>
          <div>
            <h3 className='text-white font-semibold'>最近活动</h3>
            <p className='text-blue-200 text-sm'>链上交易记录</p>
          </div>
        </div>
        <button className='text-blue-300 hover:text-white text-sm transition-colors'>
          查看全部
        </button>
      </div>

      <div className='space-y-3 max-h-80 overflow-y-auto custom-scrollbar'>
        {loading ? (
          // 加载状态
          Array.from({ length: 5 }).map((_, index) => (
            <div
              key={index}
              className='flex items-center space-x-3 p-3 rounded-lg animate-pulse'
            >
              <div className='w-8 h-8 bg-white/10 rounded-full' />
              <div className='flex-1 space-y-2'>
                <div className='h-3 bg-white/10 rounded w-3/4' />
                <div className='h-2 bg-white/10 rounded w-1/2' />
              </div>
            </div>
          ))
        ) : activities.length > 0 ? (
          activities.map(activity => (
            <div
              key={activity.id}
              className='flex items-center space-x-3 p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors'
            >
              <div className='text-2xl'>{getActivityIcon(activity.type)}</div>
              <div className='flex-1 min-w-0'>
                <div className='text-white text-sm font-medium truncate'>
                  {activity.description}
                </div>
                <div className='flex items-center space-x-2 text-xs'>
                  <span className='text-blue-200'>
                    {formatTimeAgo(activity.timestamp)}
                  </span>
                  <span className={getStatusColor(activity.status)}>
                    {getStatusText(activity.status)}
                  </span>
                </div>
              </div>
              {activity.amount && activity.token && (
                <div className='text-right'>
                  <div
                    className={`text-sm font-medium ${getActivityColor(activity.type)}`}
                  >
                    {activity.amount > 0 ? '+' : ''}
                    {activity.amount.toLocaleString()}
                  </div>
                  <div className='text-xs text-blue-200'>{activity.token}</div>
                </div>
              )}
            </div>
          ))
        ) : (
          <div className='text-center py-8 text-blue-200'>暂无活动记录</div>
        )}
      </div>

      <div className='mt-4 pt-4 border-t border-white/10'>
        <button className='w-full px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm transition-colors'>
          刷新活动
        </button>
      </div>
    </div>
  );
};

export default RecentActivities;
