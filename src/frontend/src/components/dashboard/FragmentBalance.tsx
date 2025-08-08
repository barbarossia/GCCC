import React from 'react';

interface FragmentBalanceProps {
  fragments: number;
  types: {
    common: number;
    rare: number;
    epic: number;
    legendary: number;
  };
  loading: boolean;
}

const FragmentBalance: React.FC<FragmentBalanceProps> = ({
  fragments,
  types,
  loading,
}) => {
  const rarityColors = {
    common: 'text-gray-400',
    rare: 'text-blue-400',
    epic: 'text-purple-400',
    legendary: 'text-yellow-400',
  };

  const rarityLabels = {
    common: '普通',
    rare: '稀有',
    epic: '史诗',
    legendary: '传说',
  };

  return (
    <div className='glass-effect rounded-xl p-6 shadow-lg hover:shadow-xl transition-shadow'>
      <div className='flex items-center justify-between mb-4'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-violet-500 flex items-center justify-center'>
            <span className='text-white font-bold'>F</span>
          </div>
          <div>
            <h3 className='text-white font-semibold'>碎片</h3>
            <p className='text-blue-200 text-sm'>NFT合成材料</p>
          </div>
        </div>
      </div>

      <div className='space-y-3'>
        <div className='flex items-baseline space-x-2'>
          <span className='text-2xl font-bold text-white'>
            {loading ? '---' : fragments.toLocaleString()}
          </span>
          <span className='text-blue-200 text-sm'>个</span>
        </div>

        {/* 碎片类型分布 */}
        <div className='space-y-2'>
          <div className='text-xs text-blue-200 mb-2'>类型分布:</div>
          {Object.entries(types).map(([type, count]) => (
            <div key={type} className='flex justify-between items-center'>
              <span
                className={`text-xs ${rarityColors[type as keyof typeof rarityColors]}`}
              >
                {rarityLabels[type as keyof typeof rarityLabels]}
              </span>
              <span className='text-xs text-white'>
                {loading ? '--' : count.toLocaleString()}
              </span>
            </div>
          ))}
        </div>

        {/* 合成提示 */}
        <div className='text-xs text-blue-200 pt-2 border-t border-white/10'>
          <div>• 10个普通碎片 → 1个稀有碎片</div>
          <div>• 5个稀有碎片 → 1个史诗碎片</div>
          <div>• 3个史诗碎片 → 1个传说碎片</div>
        </div>
      </div>

      <div className='flex space-x-2 mt-4'>
        <button className='flex-1 px-3 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm transition-colors'>
          合成
        </button>
        <button className='flex-1 px-3 py-2 bg-pink-500 hover:bg-pink-600 text-white rounded-lg text-sm transition-colors'>
          市场
        </button>
      </div>
    </div>
  );
};

export default FragmentBalance;
