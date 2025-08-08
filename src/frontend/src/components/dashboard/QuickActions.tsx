import React from 'react';

interface QuickAction {
  id: string;
  label: string;
  icon: string;
  color: string;
  path?: string;
  onClick?: () => void;
  disabled?: boolean;
}

interface QuickActionsProps {
  actions?: QuickAction[];
}

const defaultActions: QuickAction[] = [
  {
    id: 'vote',
    label: '参与投票',
    icon: '🗳️',
    color: 'from-blue-500 to-purple-500',
    path: '/vote',
  },
  {
    id: 'stake',
    label: '质押挖矿',
    icon: '🔒',
    color: 'from-green-500 to-blue-500',
    path: '/stake',
  },
  {
    id: 'trade',
    label: '交易市场',
    icon: '💹',
    color: 'from-purple-500 to-pink-500',
    path: '/trade',
  },
  {
    id: 'mint',
    label: '铸造NFT',
    icon: '🔨',
    color: 'from-yellow-500 to-orange-500',
    path: '/mint',
  },
  {
    id: 'referral',
    label: '邀请好友',
    icon: '👥',
    color: 'from-indigo-500 to-purple-500',
    path: '/referral',
  },
  {
    id: 'claim',
    label: '领取奖励',
    icon: '🎁',
    color: 'from-pink-500 to-red-500',
    path: '/claim',
  },
];

const QuickActions: React.FC<QuickActionsProps> = ({
  actions = defaultActions,
}) => {
  const handleActionClick = (action: QuickAction) => {
    if (action.disabled) return;

    if (action.onClick) {
      action.onClick();
    } else if (action.path) {
      // 这里应该使用路由导航，暂时用 window.location
      console.log(`Navigate to: ${action.path}`);
    }
  };

  return (
    <div className='glass-effect rounded-xl p-6 shadow-lg'>
      <div className='flex items-center space-x-3 mb-6'>
        <div className='w-10 h-10 rounded-full bg-gradient-to-r from-cyan-500 to-blue-500 flex items-center justify-center'>
          <span className='text-white font-bold'>⚡</span>
        </div>
        <div>
          <h3 className='text-white font-semibold'>快捷操作</h3>
          <p className='text-blue-200 text-sm'>常用功能入口</p>
        </div>
      </div>

      <div className='grid grid-cols-2 gap-4'>
        {actions.map(action => (
          <button
            key={action.id}
            onClick={() => handleActionClick(action)}
            disabled={action.disabled}
            className={`
              relative p-4 rounded-xl transition-all duration-300 group
              ${
                action.disabled
                  ? 'opacity-50 cursor-not-allowed'
                  : 'hover:scale-105 hover:shadow-lg cursor-pointer'
              }
            `}
          >
            {/* 背景渐变 */}
            <div
              className={`
              absolute inset-0 rounded-xl bg-gradient-to-r ${action.color} opacity-20
              ${!action.disabled && 'group-hover:opacity-30'}
              transition-opacity duration-300
            `}
            />

            {/* 内容 */}
            <div className='relative flex flex-col items-center space-y-2'>
              <div className='text-2xl'>{action.icon}</div>
              <span className='text-white text-sm font-medium text-center'>
                {action.label}
              </span>
            </div>

            {/* 悬停效果 */}
            {!action.disabled && (
              <div className='absolute inset-0 rounded-xl border border-white/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300' />
            )}
          </button>
        ))}
      </div>

      {/* 底部提示 */}
      <div className='mt-6 pt-4 border-t border-white/10'>
        <div className='text-xs text-blue-200 text-center'>
          💡 每日完成任务可获得积分奖励
        </div>
      </div>
    </div>
  );
};

export default QuickActions;
