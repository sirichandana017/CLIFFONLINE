import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Building2 } from 'lucide-react';
import { AuthForm } from '../components/AuthForm';

export function AuthPage() {
  const { userType } = useParams<{ userType: string }>();
  const navigate = useNavigate();

  // Validate user type
  React.useEffect(() => {
    const validTypes = ['wholesaler', 'retailer', 'customer'];
    if (!validTypes.includes(userType || '')) {
      navigate('/');
    }
  }, [userType, navigate]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50">
      {/* Header */}
      <header className="w-full bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center space-x-3">
            <Building2 className="h-8 w-8 text-blue-600" />
            <h1 className="text-2xl font-bold text-gray-900">MarketConnect</h1>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="max-w-md mx-auto px-4 py-12">
        <div className="bg-white rounded-xl shadow-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
            {userType === 'wholesaler'
              ? 'Wholesaler Registration'
              : userType === 'retailer'
              ? 'Retailer Registration'
              : 'Customer Registration'}
          </h2>
          <AuthForm />
        </div>
      </main>
    </div>
  );
}