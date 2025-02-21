import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Building2, LogOut } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { WholesalerDashboard } from '../components/wholesaler/WholesalerDashboard';
import { RetailerDashboard } from '../components/retailer/RetailerDashboard';
import toast from 'react-hot-toast';

export function DashboardPage() {
  const { userType } = useParams<{ userType: string }>();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [userData, setUserData] = useState<any>(null);

  useEffect(() => {
    const validTypes = ['wholesaler', 'retailer', 'customer'];
    if (!validTypes.includes(userType || '')) {
      navigate('/');
    }
  }, [userType, navigate]);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
          navigate(`/${userType}/auth`);
          return;
        }

        // Get user profile data
        const { data: profile, error } = await supabase
          .from('user_profiles')
          .select('*')
          .eq('id', user.id)
          .single();

        if (error) throw error;

        if (profile.user_type !== userType) {
          toast.error('Unauthorized access');
          navigate(`/${profile.user_type}/dashboard`);
          return;
        }

        setUserData({ ...user, profile });
      } catch (error) {
        console.error('Auth error:', error);
        navigate(`/${userType}/auth`);
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, [userType, navigate]);

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut();
      navigate('/');
    } catch (error) {
      console.error('Sign out error:', error);
      toast.error('Failed to sign out');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="w-full bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Building2 className="h-8 w-8 text-blue-600" />
              <h1 className="text-2xl font-bold text-gray-900">MarketConnect</h1>
            </div>
            <button
              onClick={handleSignOut}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <LogOut className="h-4 w-4 mr-2" />
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="max-w-7xl mx-auto px-4 py-8">
        {userType === 'wholesaler' && <WholesalerDashboard userData={userData} />}
        {userType === 'retailer' && <RetailerDashboard userData={userData} />}
      </main>
    </div>
  );
}