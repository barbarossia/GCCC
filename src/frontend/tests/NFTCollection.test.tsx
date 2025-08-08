import { describe, test, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import NFTCollection from '../src/components/dashboard/NFTCollection';

const mockNFTs = [
  {
    id: '001',
    name: 'Genesis Dragon',
    image: '',
    rarity: 'legendary' as const,
    level: 25,
    power: 9500,
  },
  {
    id: '002',
    name: 'Cyber Knight',
    image: '',
    rarity: 'epic' as const,
    level: 18,
    power: 6200,
  },
  {
    id: '003',
    name: 'Space Warrior',
    image: '',
    rarity: 'rare' as const,
    level: 12,
    power: 3400,
  },
  {
    id: '004',
    name: 'Fire Mage',
    image: '',
    rarity: 'common' as const,
    level: 8,
    power: 1200,
  },
];

describe('NFTCollection Component', () => {
  test('renders NFT collection correctly', () => {
    render(
      <NFTCollection nfts={mockNFTs} totalValue={156.8} loading={false} />
    );

    expect(screen.getByText('NFT 收藏')).toBeInTheDocument();
    expect(screen.getByText('4 个')).toBeInTheDocument();
    expect(screen.getByText('价值 156.80 SOL')).toBeInTheDocument();
  });

  test('shows loading state', () => {
    render(<NFTCollection nfts={[]} totalValue={0} loading={true} />);

    expect(screen.getByText('-- 个')).toBeInTheDocument();
    expect(screen.getByText('价值 -- SOL')).toBeInTheDocument();

    // Should show loading skeleton for NFT grid
    const skeletonItems = document.querySelectorAll('.animate-pulse');
    expect(skeletonItems.length).toBe(8); // 8 skeleton items
  });

  test('displays NFT items correctly', () => {
    render(
      <NFTCollection nfts={mockNFTs} totalValue={156.8} loading={false} />
    );

    // Should show NFT IDs
    expect(screen.getByText('#001')).toBeInTheDocument();
    expect(screen.getByText('#002')).toBeInTheDocument();
    expect(screen.getByText('#003')).toBeInTheDocument();
    expect(screen.getByText('#004')).toBeInTheDocument();
  });

  test('shows empty state when no NFTs', () => {
    render(<NFTCollection nfts={[]} totalValue={0} loading={false} />);

    expect(screen.getByText('暂无 NFT')).toBeInTheDocument();
  });

  test('displays action buttons', () => {
    render(
      <NFTCollection nfts={mockNFTs} totalValue={156.8} loading={false} />
    );

    expect(screen.getByText('查看全部')).toBeInTheDocument();
    expect(screen.getByText('铸造')).toBeInTheDocument();
  });

  test('shows statistics when NFTs exist', () => {
    render(
      <NFTCollection nfts={mockNFTs} totalValue={156.8} loading={false} />
    );

    expect(screen.getByText('最高等级:')).toBeInTheDocument();
    // Use getAllByText since level 25 appears in both NFT card and statistics
    expect(screen.getAllByText('25').length).toBeGreaterThan(0);

    expect(screen.getByText('总战力:')).toBeInTheDocument();
    expect(screen.getByText('20,300')).toBeInTheDocument(); // Sum of all power values
  });

  test('handles more than 8 NFTs correctly', () => {
    const manyNFTs = Array.from({ length: 12 }, (_, i) => ({
      id: String(i + 1).padStart(3, '0'),
      name: `NFT ${i + 1}`,
      image: '',
      rarity: 'common' as const,
      level: i + 1,
      power: 1000 + i * 100,
    }));

    render(<NFTCollection nfts={manyNFTs} totalValue={200} loading={false} />);

    expect(screen.getByText('12 个')).toBeInTheDocument();
    expect(screen.getByText('还有 4 个 NFT...')).toBeInTheDocument();
  });
});
