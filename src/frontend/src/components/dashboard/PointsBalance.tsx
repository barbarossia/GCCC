import React from 'react';

interface PointsBalanceProps {
  points: number;
  level: number;
  nextLevelPoints: number;
  loading: boolean;
}

const PointsBalance: React.FC<PointsBalanceProps> = ({
  points,
  level,
  nextLevelPoints,
  loading,
}) => {
  const progressToNext =
    nextLevelPoints > 0 ? (points / nextLevelPoints) * 100 : 100;
  const pointsToNext = Math.max(0, nextLevelPoints - points);

  return (
    <div className='glass-effect rounded-xl p-6 shadow-lg hover:shadow-xl transition-shadow'>
      <div className='flex items-center justify-between mb-4'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 flex items-center justify-center'>
            <span className='text-white font-bold'>P</span>
          </div>
          <div>
            <h3 className='text-white font-semibold'>积分</h3>
            <p className='text-blue-200 text-sm'>社区贡献值</p>
          </div>
        </div>
        <div className='text-right'>
          <div className='px-2 py-1 bg-purple-500/20 rounded-full'>
            <span className='text-purple-300 text-xs font-medium'>
              Lv.{level}
            </span>
          </div>
        </div>
      </div>

      <div className='space-y-3'>
        <div className='flex items-baseline space-x-2'>
          <span className='text-2xl font-bold text-white'>
            {loading ? '---' : points.toLocaleString()}
          </span>
          <span className='text-blue-200 text-sm'>分</span>
        </div>

        {/* 等级进度 */}
        <div className='space-y-2'>
          <div className='flex justify-between text-xs text-blue-200'>
            <span>下级还需:</span>
            <span>
              {loading
                ? '---'
                : pointsToNext > 0
                  ? pointsToNext.toLocaleString()
                  : '已满级'}
            </span>
          </div>

          {pointsToNext > 0 && (
            <div className='w-full bg-white/10 rounded-full h-2'>
              <div
                className='bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full transition-all duration-500'
                style={{ width: `${Math.min(progressToNext, 100)}%` }}
              />
            </div>
          )}
        </div>

        {/* 积分来源提示 */}
        <div className='text-xs text-blue-200 space-y-1'>
          <div>• 每日签到: +10分</div>
          <div>• 参与投票: +50分</div>
          <div>• 推荐用户: +100分</div>
        </div>
      </div>

      <div className='flex space-x-2 mt-4'>
        <button className='flex-1 px-3 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm transition-colors'>
          签到
        </button>
        <button className='flex-1 px-3 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg text-sm transition-colors'>
          任务
        </button>
      </div>
    </div>
  );
};

export default PointsBalance;
