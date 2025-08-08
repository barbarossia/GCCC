import React from 'react';

interface SOLBalanceProps {
  balance: number;
  loading: boolean;
}

const SOLBalance: React.FC<SOLBalanceProps> = ({ balance, loading }) => {
  const usdValue = balance * 150; // Mock SOL price $150

  return (
    <div className='glass-effect rounded-xl p-6 shadow-lg hover:shadow-xl transition-shadow'>
      <div className='flex items-center justify-between mb-4'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 rounded-full bg-gradient-to-r from-purple-500 to-indigo-500 flex items-center justify-center'>
            <span className='text-white font-bold'>◉</span>
          </div>
          <div>
            <h3 className='text-white font-semibold'>SOL</h3>
            <p className='text-blue-200 text-sm'>Solana</p>
          </div>
        </div>
      </div>

      <div className='space-y-2'>
        <div className='flex items-baseline space-x-2'>
          <span className='text-2xl font-bold text-white'>
            {loading ? '---' : balance.toFixed(4)}
          </span>
          <span className='text-blue-200 text-sm'>SOL</span>
        </div>

        <div className='text-blue-200 text-sm'>
          ≈ ${loading ? '---' : usdValue.toFixed(2)}
        </div>
      </div>

      <div className='flex space-x-2 mt-4'>
        <button className='flex-1 px-3 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm transition-colors'>
          接收
        </button>
        <button className='flex-1 px-3 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg text-sm transition-colors'>
          发送
        </button>
      </div>
    </div>
  );
};

export default SOLBalance;
