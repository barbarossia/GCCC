import React from 'react';

interface NFTItem {
  id: string;
  name: string;
  image: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  level: number;
  power: number;
}

interface NFTCollectionProps {
  nfts: NFTItem[];
  totalValue: number;
  loading: boolean;
}

const NFTCollection: React.FC<NFTCollectionProps> = ({
  nfts,
  totalValue,
  loading,
}) => {
  const rarityColors = {
    common: 'border-gray-400',
    rare: 'border-blue-400',
    epic: 'border-purple-400',
    legendary: 'border-yellow-400',
  };

  const rarityBg = {
    common: 'bg-gray-400/20',
    rare: 'bg-blue-400/20',
    epic: 'bg-purple-400/20',
    legendary: 'bg-yellow-400/20',
  };

  return (
    <div className='glass-effect rounded-xl p-6 shadow-lg'>
      <div className='flex items-center justify-between mb-4'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 rounded-full bg-gradient-to-r from-indigo-500 to-purple-500 flex items-center justify-center'>
            <span className='text-white font-bold'>N</span>
          </div>
          <div>
            <h3 className='text-white font-semibold'>NFT 收藏</h3>
            <p className='text-blue-200 text-sm'>数字资产</p>
          </div>
        </div>
        <div className='text-right'>
          <div className='text-sm text-white font-medium'>
            {loading ? '--' : nfts.length} 个
          </div>
          <div className='text-xs text-blue-200'>
            价值 {loading ? '--' : totalValue.toFixed(2)} SOL
          </div>
        </div>
      </div>

      <div className='space-y-4'>
        {/* NFT 网格 */}
        <div className='grid grid-cols-4 gap-2'>
          {loading ? (
            // 加载状态
            Array.from({ length: 8 }).map((_, index) => (
              <div
                key={index}
                className='aspect-square bg-white/10 rounded-lg animate-pulse'
              />
            ))
          ) : nfts.length > 0 ? (
            nfts.slice(0, 8).map(nft => (
              <div
                key={nft.id}
                className={`aspect-square rounded-lg border-2 ${rarityColors[nft.rarity]} ${rarityBg[nft.rarity]} p-1 hover:scale-105 transition-transform cursor-pointer`}
              >
                <div className='w-full h-full bg-white/10 rounded flex items-center justify-center relative'>
                  <span className='text-white text-xs font-bold'>
                    #{nft.id}
                  </span>
                  <div className='absolute bottom-0 right-0 text-xs text-white bg-black/50 px-1 rounded'>
                    {nft.level}
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className='col-span-4 text-center py-8 text-blue-200'>
              暂无 NFT
            </div>
          )}
        </div>

        {nfts.length > 8 && (
          <div className='text-center text-xs text-blue-200'>
            还有 {nfts.length - 8} 个 NFT...
          </div>
        )}

        {/* 统计信息 */}
        {nfts.length > 0 && (
          <div className='text-xs text-blue-200 space-y-1 pt-2 border-t border-white/10'>
            <div className='flex justify-between'>
              <span>最高等级:</span>
              <span>{Math.max(...nfts.map(n => n.level))}</span>
            </div>
            <div className='flex justify-between'>
              <span>总战力:</span>
              <span>
                {nfts.reduce((sum, n) => sum + n.power, 0).toLocaleString()}
              </span>
            </div>
          </div>
        )}
      </div>

      <div className='flex space-x-2 mt-4'>
        <button className='flex-1 px-3 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm transition-colors'>
          查看全部
        </button>
        <button className='flex-1 px-3 py-2 bg-indigo-500 hover:bg-indigo-600 text-white rounded-lg text-sm transition-colors'>
          铸造
        </button>
      </div>
    </div>
  );
};

export default NFTCollection;
