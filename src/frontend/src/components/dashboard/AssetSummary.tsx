import React from 'react';

interface AssetSummaryProps {
  data: {
    totalValue: number;
    solBalance?: number;
    gCCCBalance?: number;
    points: number;
    sol?: number;
    gccc?: number;
  } | null;
  loading: boolean;
  onRefresh: () => void;
}

const AssetSummary: React.FC<AssetSummaryProps> = ({
  data,
  loading,
  onRefresh,
}) => {
  return (
    <div className='glass-effect rounded-2xl p-6 shadow-xl'>
      <div className='flex justify-between items-center mb-4'>
        <h3 className='text-lg font-semibold text-white'>资产总览</h3>
        <button
          onClick={onRefresh}
          disabled={loading}
          className='p-2 hover:bg-white/10 rounded-lg transition-colors disabled:opacity-50'
        >
          <span
            className={`text-white text-lg ${loading ? 'animate-spin' : ''}`}
          >
            🔄
          </span>
        </button>
      </div>

      <div className='space-y-4'>
        <div>
          <div className='text-3xl font-bold text-white'>
            $
            {loading || !data
              ? '---'
              : data.totalValue.toLocaleString(undefined, {
                  minimumFractionDigits: 2,
                })}
          </div>
          <div className='text-blue-200 text-sm'>总资产价值 (USD)</div>
        </div>

        <div className='grid grid-cols-1 gap-3'>
          <div className='flex justify-between items-center'>
            <span className='text-blue-200'>SOL</span>
            <span className='text-white font-medium'>
              {loading || !data
                ? '---'
                : (data.sol || data.solBalance || 0).toFixed(4)}
            </span>
          </div>
          <div className='flex justify-between items-center'>
            <span className='text-blue-200'>GCCC</span>
            <span className='text-white font-medium'>
              {loading || !data
                ? '---'
                : (data.gccc || data.gCCCBalance || 0).toLocaleString()}
            </span>
          </div>
          <div className='flex justify-between items-center'>
            <span className='text-blue-200'>积分</span>
            <span className='text-white font-medium'>
              {loading || !data ? '---' : data.points.toLocaleString()}
            </span>
          </div>
        </div>

        <div className='pt-3 border-t border-white/20'>
          <div className='text-green-400 text-sm'>📈 24小时变化: +2.34%</div>
        </div>
      </div>
    </div>
  );
};

export default AssetSummary;
