# React Development Standards

Binding standards for all React components, hooks, and patterns in technical specifications.

## TypeScript Configuration

### Strict Mode (Mandatory)
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

### No `any` Type
```tsx
// BAD
const user: any = data;

// GOOD
interface User {
  id: string;
  email: string;
}
const user: User = data;
```

## Component Architecture

### Functional Components Only
No class components. All components are functional with hooks.

```tsx
// GOOD: Functional component
export const UserCard: React.FC<UserCardProps> = ({ user }) => {
  return <div>{user.name}</div>;
};

// BAD: Class component
class UserCard extends React.Component { ... }
```

### Component Props Interface
Every component must have a typed props interface.

```tsx
interface UserCardProps {
  user: User;
  onEdit?: (id: string) => void;
  isLoading?: boolean;
}

export const UserCard: React.FC<UserCardProps> = ({
  user,
  onEdit,
  isLoading = false
}) => {
  return (
    <div className="user-card">
      <h2>{user.name}</h2>
      <p>{user.email}</p>
      {onEdit && (
        <button onClick={() => onEdit(user.id)} disabled={isLoading}>
          Edit
        </button>
      )}
    </div>
  );
};
```

## Hooks and Custom Hooks

### Built-in Hooks Rules
- `useState`: For component-local state
- `useEffect`: For side effects (API calls, subscriptions)
- `useCallback`: For memoized callbacks passed to children (performance)
- `useMemo`: For expensive computations (performance)
- `useRef`: For DOM access, mutable values
- `useContext`: For theme, language, auth (not general state)

### Dependency Array (Critical)
Always include complete dependency array in `useEffect` and `useCallback`.

```tsx
// GOOD
useEffect(() => {
  fetchUser(userId);
}, [userId]); // Refetch when userId changes

// BAD: Missing dependency
useEffect(() => {
  fetchUser(userId); // userId could be stale
}, []); // Empty array = never re-run

// BAD: Too broad
useEffect(() => {
  fetchUser(userId);
}, [data]); // What if data has other unrelated changes?
```

### Custom Hooks Pattern
Extract component logic into reusable hooks.

```tsx
// hooks/useUserForm.ts
interface UseUserFormReturn {
  formData: UserFormData;
  updateField: (field: keyof UserFormData, value: string) => void;
  errors: Record<string, string>;
  validate: () => boolean;
  reset: () => void;
}

export const useUserForm = (): UseUserFormReturn => {
  const [formData, setFormData] = useState<UserFormData>({
    email: '',
    name: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const updateField = useCallback((field: keyof UserFormData, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    setErrors((prev) => ({ ...prev, [field]: '' })); // Clear error on change
  }, []);

  const validate = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};

    if (!isValidEmail(formData.email)) {
      newErrors.email = 'Invalid email';
    }
    if (formData.name.trim().length === 0) {
      newErrors.name = 'Name required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [formData]);

  const reset = useCallback(() => {
    setFormData({ email: '', name: '' });
    setErrors({});
  }, []);

  return { formData, updateField, errors, validate, reset };
};
```

## State Management

### Component-Local State vs Global State
- **Component state:** UI state (isOpen, selectedTab, form values)
- **Global state:** Auth user, theme, language, shared data across pages

### React Query (Server State)
```tsx
import { useQuery, useMutation } from '@tanstack/react-query';

// Fetching data
const { data: users, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: () => userApi.getUsers(),
});

// Mutating data
const { mutate: deleteUser } = useMutation({
  mutationFn: (id: string) => userApi.deleteUser(id),
  onSuccess: () => {
    // Invalidate cache to refetch
    queryClient.invalidateQueries({ queryKey: ['users'] });
  },
  onError: (error) => {
    console.error('Delete failed:', error);
  },
});
```

### Zustand (Client State)
```tsx
import { create } from 'zustand';

interface AppStore {
  theme: 'light' | 'dark';
  setTheme: (theme: 'light' | 'dark') => void;
}

export const useAppStore = create<AppStore>((set) => ({
  theme: 'light',
  setTheme: (theme) => set({ theme }),
}));

// Usage in component
export const ThemeToggle = () => {
  const { theme, setTheme } = useAppStore();

  return (
    <button onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}>
      {theme}
    </button>
  );
};
```

## Performance Optimization

### useMemo and useCallback Criteria
Only use when:
1. Component re-renders frequently
2. Expensive computation or large object creation
3. Prop passed to memoized child component

**Avoid premature optimization:**
```tsx
// BAD: Over-optimized
const expensiveValue = useMemo(() => ({ id: 1 }), []);

// GOOD: Only optimize if needed
const expensiveValue = useMemo(
  () => complexCalculation(data),
  [data]
);
```

### React.memo
Memoize component if props are rarely updated.

```tsx
interface ButtonProps {
  label: string;
  onClick: () => void;
}

// Without memo: Re-renders on every parent render
export const SmallButton = ({ label, onClick }: ButtonProps) => (
  <button onClick={onClick}>{label}</button>
);

// With memo: Only re-renders if props change
export const OptimizedButton = React.memo(({ label, onClick }: ButtonProps) => (
  <button onClick={onClick}>{label}</button>
));
```

## Error Handling and Boundaries

### Error Boundary Component
```tsx
interface ErrorBoundaryProps {
  children: React.ReactNode;
  fallback?: (error: Error) => React.ReactNode;
}

export class ErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  { hasError: boolean; error: Error | null }
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback?.(this.state.error!) || (
          <div className="error">
            <h2>Something went wrong</h2>
            <p>{this.state.error?.message}</p>
          </div>
        )
      );
    }

    return this.props.children;
  }
}

// Usage
<ErrorBoundary>
  <Dashboard />
</ErrorBoundary>
```

### Async Error Handling
```tsx
export const UserPage = () => {
  const [error, setError] = useState<string | null>(null);

  const { mutate: loadUser } = useMutation({
    mutationFn: (id: string) => userApi.getUser(id),
    onError: (error) => {
      if (error instanceof Error) {
        setError(error.message);
      } else {
        setError('Unknown error occurred');
      }
    },
  });

  if (error) {
    return <div className="error">{error}</div>;
  }

  return <div>{/* ... */}</div>;
};
```

## Testing Standards

### Test Setup
- **Framework:** Vitest
- **Component Testing:** React Testing Library
- **Avoid:** Enzyme, shallow rendering
- **Utilities:** User event, screen queries

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  it('should call onClick when clicked', async () => {
    const handleClick = vi.fn();
    render(<Button label="Click me" onClick={handleClick} />);

    const button = screen.getByRole('button', { name: /click me/i });
    await userEvent.click(button);

    expect(handleClick).toHaveBeenCalled();
  });

  it('should be disabled when disabled prop is true', () => {
    render(<Button label="Click me" onClick={() => {}} disabled={true} />);

    const button = screen.getByRole('button');
    expect(button).toBeDisabled();
  });
});
```

### Hook Testing
```tsx
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('should increment counter', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

## Accessibility (a11y)

### Semantic HTML
```tsx
// GOOD: Semantic HTML
<button onClick={handleClick}>Delete</button>
<nav>{/* ... */}</nav>
<main>{/* ... */}</main>
<aside>{/* ... */}</aside>

// BAD: Non-semantic
<div onClick={handleClick}>Delete</div>
<div role="navigation">{/* ... */}</div>
```

### ARIA Attributes
```tsx
// Form accessibility
<label htmlFor="email">Email:</label>
<input id="email" type="email" />

// Dialog accessibility
<div role="dialog" aria-labelledby="title" aria-modal="true">
  <h2 id="title">Confirm Action</h2>
  <p>Are you sure?</p>
</div>

// Loading state
<div aria-busy="true" aria-label="Loading...">
  {/* ... */}
</div>
```

### Focus Management
```tsx
export const Modal = ({ isOpen, onClose }: ModalProps) => {
  const closeButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (isOpen) {
      // Focus close button when modal opens
      closeButtonRef.current?.focus();
    }
  }, [isOpen]);

  return (
    <dialog open={isOpen}>
      <h2>Modal Title</h2>
      <button ref={closeButtonRef} onClick={onClose}>
        Close
      </button>
    </dialog>
  );
};
```

## Code Style and Organization

### Naming Conventions
- Components: PascalCase (`UserCard`, `FormField`)
- Hooks: camelCase, start with "use" (`useAuth`, `useUserForm`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`, `DEFAULT_TIMEOUT`)
- Private/internal: prefix with underscore (`_helper`, `_internal`)

### File Organization
```
components/
├── atoms/
│   └── Button.tsx        ← Component file includes styles if co-located
├── hooks/
│   └── useAuth.ts
├── services/
│   └── api.ts
└── types/
    └── domain.ts
```

### Import Organization
```tsx
// 1. React and external libraries
import React, { useState, useCallback } from 'react';
import { useQuery } from '@tanstack/react-query';

// 2. Local imports
import { Button } from '../atoms/Button';
import { useAuth } from '../hooks/useAuth';
import { userApi } from '../services/api';
import { User } from '../types/domain';

// 3. Styles
import './UserCard.css';
```

## Responsive Design

### Mobile-First Approach
```tsx
export const Grid = styled.div`
  display: grid;
  grid-template-columns: 1fr; /* Mobile: 1 column */
  gap: 16px;

  @media (min-width: 768px) {
    grid-template-columns: repeat(2, 1fr); /* Tablet: 2 columns */
  }

  @media (min-width: 1024px) {
    grid-template-columns: repeat(3, 1fr); /* Desktop: 3 columns */
  }
`;
```

### Viewport Meta Tag
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

## Environment Variables

### Vite Configuration
```
VITE_API_URL=https://api.example.com
VITE_LOG_LEVEL=error
```

### Usage in Code
```tsx
const apiUrl = import.meta.env.VITE_API_URL;
const logLevel = import.meta.env.VITE_LOG_LEVEL;

// Never:
// - Commit `.env` files
// - Expose API keys
// - Put secrets in frontend
```

## Anti-Patterns to Avoid

### ❌ Prop Drilling
```tsx
// BAD: Props passed through many levels
<Layout user={user}>
  <Dashboard user={user}>
    <Sidebar user={user}>
      <UserMenu user={user} />
    </Sidebar>
  </Dashboard>
</Layout>

// GOOD: Use context or state management
const { user } = useAuthStore();
// Access in UserMenu without prop drilling
```

### ❌ Inline Functions in Renders
```tsx
// BAD: New function created every render
<button onClick={() => setCount(count + 1)}>Increment</button>

// GOOD: Use useCallback
const increment = useCallback(() => setCount(count + 1), [count]);
<button onClick={increment}>Increment</button>
```

### ❌ Missing Keys in Lists
```tsx
// BAD: No key or index as key
{items.map((item) => <div>{item.name}</div>)}
{items.map((item, index) => <div key={index}>{item.name}</div>)}

// GOOD: Stable unique key
{items.map((item) => <div key={item.id}>{item.name}</div>)}
```

### ❌ State Updates Inside Render
```tsx
// BAD: Infinite loop
export const Counter = () => {
  const [count, setCount] = useState(0);
  setCount(count + 1); // Called every render!

  return <div>{count}</div>;
};

// GOOD: Use useEffect
export const Counter = () => {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => setCount(c => c + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  return <div>{count}</div>;
};
```

### ❌ Using `any` Type
```tsx
// BAD
const data: any = fetchData();
data.user.name; // No type safety

// GOOD
interface ApiResponse {
  user: { name: string };
}
const data: ApiResponse = fetchData();
data.user.name; // Type-safe
```

---

**Last Updated:** 2026-07-01
