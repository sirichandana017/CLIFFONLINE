import { Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { HomePage } from './pages/HomePage';
import { AuthPage } from './pages/AuthPage';
import { DashboardPage } from './pages/DashboardPage';

function App() {
  return (
    <>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/:userType/auth" element={<AuthPage />} />
        <Route path="/:userType/dashboard" element={<DashboardPage />} />
      </Routes>
      <Toaster position="top-right" />
    </>
  );
}

export default App;