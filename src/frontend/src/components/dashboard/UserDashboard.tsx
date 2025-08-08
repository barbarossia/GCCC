import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import UserProfileCard from './UserProfileCard';
import AssetSummary from './AssetSummary';
import SOLBalance from './SOLBalance';
import GCCCBalance from './GCCCBalance';
import PointsBalance from './PointsBalance';
import NFTCollection from './NFTCollection';
import FragmentBalance from './FragmentBalance';
import RecentActivities from './RecentActivities';
import QuickActions from './QuickActions';

// Enhanced data interfaces
interface AssetData {
  totalValue: number;
  change24h: number;
  solBalance: number;
  gCCCBalance: number;
  gCCCStaked: number;
  points: number;
  pointsLevel: number;
  nextLevelPoints: number;
  fragments: number;
  fragmentTypes: {
    common: number;
    rare: number;
    epic: number;
    legendary: number;
  };
  nftCount: number;
  nfts: Array<{
    id: string;
    name: string;
    image: string;
    rarity: 'common' | 'rare' | 'epic' | 'legendary';
    level: number;
    power: number;
  }>;
  nftTotalValue: number;
  recentActivities: Array<{
    id: string;
    type: 'vote' | 'stake' | 'trade' | 'mint' | 'claim' | 'transfer';
    description: string;
    amount?: number;
    token?: string;
    timestamp: Date;
    status: 'success' | 'pending' | 'failed';
  }>;
  lastUpdated: Date;
}

interface UserData {
  username: string;
  level: number;
  vipLevel: number;
  avatar: string;
  joinDate: string;
  totalAssets: number;
  vipProgress: number;
}

const UserDashboard: React.FC = () => {
  const { user, signOut } = useAuth();
  const [loading, setLoading] = useState(true);
  const [userData, setUserData] = useState<UserData | null>(null);
  const [assetData, setAssetData] = useState<AssetData | null>(null);

  // Enhanced mock data loading
  useEffect(() => {
    const loadData = async () => {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1500));

      // Set user profile data
      if (user) {
        setUserData({
          username: user.username || '加密玩家2024',
          level: 15,
          vipLevel: 3,
          avatar: user.avatar || '',
          joinDate: '2024-01-15',
          totalAssets: 12450.67,
          vipProgress: 68,
        });
      }

      // Set comprehensive asset data
      setAssetData({
        totalValue: 12450.67,
        change24h: 5.67,
        solBalance: 45.23,
        gCCCBalance: 850000,
        gCCCStaked: 400000,
        points: 8950,
        pointsLevel: 15,
        nextLevelPoints: 10000,
        fragments: 247,
        fragmentTypes: {
          common: 180,
          rare: 45,
          epic: 18,
          legendary: 4,
        },
        nftCount: 12,
        nfts: [
          {
            id: '001',
            name: 'Genesis Dragon',
            image: '',
            rarity: 'legendary',
            level: 25,
            power: 9500,
          },
          {
            id: '002',
            name: 'Cyber Knight',
            image: '',
            rarity: 'epic',
            level: 18,
            power: 6200,
          },
          {
            id: '003',
            name: 'Space Warrior',
            image: '',
            rarity: 'rare',
            level: 12,
            power: 3400,
          },
          {
            id: '004',
            name: 'Fire Mage',
            image: '',
            rarity: 'epic',
            level: 20,
            power: 7100,
          },
          {
            id: '005',
            name: 'Ice Guardian',
            image: '',
            rarity: 'rare',
            level: 15,
            power: 4200,
          },
          {
            id: '006',
            name: 'Lightning Bolt',
            image: '',
            rarity: 'common',
            level: 8,
            power: 1200,
          },
          {
            id: '007',
            name: 'Earth Titan',
            image: '',
            rarity: 'epic',
            level: 22,
            power: 7800,
          },
          {
            id: '008',
            name: 'Wind Spirit',
            image: '',
            rarity: 'rare',
            level: 14,
            power: 3800,
          },
        ],
        nftTotalValue: 156.8,
        recentActivities: [
          {
            id: '1',
            type: 'vote',
            description: '参与社区治理投票 #234',
            amount: 50,
            token: 'POINTS',
            timestamp: new Date(Date.now() - 1000 * 60 * 30),
            status: 'success',
          },
          {
            id: '2',
            type: 'stake',
            description: '质押 GCCC 代币',
            amount: 50000,
            token: 'GCCC',
            timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2),
            status: 'success',
          },
          {
            id: '3',
            type: 'mint',
            description: '铸造 NFT: Cyber Knight',
            timestamp: new Date(Date.now() - 1000 * 60 * 60 * 6),
            status: 'success',
          },
          {
            id: '4',
            type: 'trade',
            description: '购买碎片材料',
            amount: -2.5,
            token: 'SOL',
            timestamp: new Date(Date.now() - 1000 * 60 * 60 * 12),
            status: 'success',
          },
          {
            id: '5',
            type: 'claim',
            description: '领取每日签到奖励',
            amount: 10,
            token: 'POINTS',
            timestamp: new Date(Date.now() - 1000 * 60 * 60 * 20),
            status: 'success',
          },
        ],
        lastUpdated: new Date(),
      });

      setLoading(false);
    };

    loadData();
  }, [user]);

  const handleRefresh = async () => {
    setLoading(true);
    // Simulate refresh
    await new Promise(resolve => setTimeout(resolve, 1000));
    setLoading(false);
  };

  if (!user) return null;

  return (
    <div className='min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-6'>
      <div className='max-w-7xl mx-auto space-y-6'>
        {/* Header */}
        <div className='flex items-center justify-between'>
          <h1 className='text-3xl font-bold text-white'>用户仪表盘</h1>
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

        {/* Main Grid */}
        <div className='grid grid-cols-1 xl:grid-cols-4 gap-6'>
          {/* Left Column - Profile & Quick Actions */}
          <div className='space-y-6'>
            <UserProfileCard user={userData} />

            <QuickActions />
          </div>

          {/* Middle Left Column - Balances */}
          <div className='space-y-6'>
            <AssetSummary
              data={assetData}
              loading={loading}
              onRefresh={handleRefresh}
            />

            <SOLBalance
              balance={assetData?.solBalance || 0}
              loading={loading}
            />

            <GCCCBalance
              balance={assetData?.gCCCBalance || 0}
              staked={assetData?.gCCCStaked || 0}
              loading={loading}
            />
          </div>

          {/* Middle Right Column - Points & Fragments */}
          <div className='space-y-6'>
            <PointsBalance
              points={assetData?.points || 0}
              level={assetData?.pointsLevel || 1}
              nextLevelPoints={assetData?.nextLevelPoints || 1000}
              loading={loading}
            />

            <FragmentBalance
              fragments={assetData?.fragments || 0}
              types={
                assetData?.fragmentTypes || {
                  common: 0,
                  rare: 0,
                  epic: 0,
                  legendary: 0,
                }
              }
              loading={loading}
            />
          </div>

          {/* Right Column - NFTs & Activities */}
          <div className='space-y-6'>
            <NFTCollection
              nfts={assetData?.nfts || []}
              totalValue={assetData?.nftTotalValue || 0}
              loading={loading}
            />

            <RecentActivities
              activities={assetData?.recentActivities || []}
              loading={loading}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserDashboard;
