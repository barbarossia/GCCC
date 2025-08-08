import React from 'react';

interface GCCCBalanceProps {
  balance: number;
  staked: number;
  loading: boolean;
}

const GCCCBalance: React.FC<GCCCBalanceProps> = ({
  balance,
  staked,
  loading,
}) => {
  const total = balance + staked;
  const stakingRatio = total > 0 ? (staked / total) * 100 : 0;

  return (
    <div className='glass-effect rounded-xl p-6 shadow-lg hover:shadow-xl transition-shadow'>
      <div className='flex items-center justify-between mb-4'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 rounded-full bg-gradient-to-r from-yellow-500 to-orange-500 flex items-center justify-center'>
            <span className='text-white font-bold'>G</span>
          </div>
          <div>
            <h3 className='text-white font-semibold'>GCCC</h3>
            <p className='text-blue-200 text-sm'>治理代币</p>
          </div>
        </div>
      </div>

      <div className='space-y-2'>
        <div className='flex items-baseline space-x-2'>
          <span className='text-2xl font-bold text-white'>
            {loading ? '---' : total.toLocaleString()}
          </span>
          <span className='text-blue-200 text-sm'>GCCC</span>
        </div>

        <div className='text-xs space-y-1'>
          <div className='flex justify-between text-blue-200'>
            <span>可用:</span>
            <span>{loading ? '---' : balance.toLocaleString()}</span>
          </div>
          <div className='flex justify-between text-blue-200'>
            <span>质押:</span>
            <span>{loading ? '---' : staked.toLocaleString()}</span>
          </div>
        </div>

        {staked > 0 && (
          <div className='pt-2'>
            <div className='text-xs text-blue-200 mb-1'>
              质押比例: {stakingRatio.toFixed(1)}%
            </div>
            <div className='text-xs text-green-400'>预估年收益: ~8% APY</div>
          </div>
        )}
      </div>

      <div className='flex space-x-2 mt-4'>
        <button className='flex-1 px-3 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm transition-colors'>
          质押
        </button>
        <button className='flex-1 px-3 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg text-sm transition-colors'>
          治理
        </button>
      </div>
    </div>
  );
};

export default GCCCBalance;
