import { AuthProvider } from './contexts/AuthContext';
import AuthApp from './components/AuthApp';

function App() {
  return (
    <AuthProvider>
      <div className="min-h-screen">
        <AuthApp />
      </div>
    </AuthProvider>
  );
}

export default App;
