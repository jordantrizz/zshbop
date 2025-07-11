# Workers
## Wrangler Install
```
npm install -g wrangler --location=global
```

## Dummy IP for DNS Record
If you setup a worker and want to use a DNS record under your domain to map to the worker. You have to setup a DNS record, and it can use a dummy IP.
```
192.0.2.1
```

## Testing Firewall Rules
* Use firewalkeer to test firewall rules https://github.com/SerCeMan/firewalker

1. Clone the repository
```git clone https://github.com/SerCeMan/firewalker.git```
2. Install dependencies
```yarn install```
3. Run the tests
```yarn test```
4. Add your tests to the ```tests``` folder

### Example

```
import {Firewall, Request} from '../src';
import {URLSearchParams} from 'url';

describe('Standard fields', () => {
    let firewall: Firewall;

    beforeEach(() => {
        firewall = new Firewall();
    });

    it('Testing Original Rule', () => {
        # Cloudflare expression to test.
        const rule = firewall.createRule(`
        (http.request.uri.path contains "/wp-login.php")
        or (http.request.uri.path contains "/wp-admin/" and http.request.uri.path ne "/wp-admin/admin-ajax.php")        
        `);

        # Tests to run on the expression.
        expect(rule.match(new Request('http://example.org/wp-admin/'))).toBeTruthy();
        expect(rule.match(new Request('http://example.org/wp-admin/admin-ajax.php'))).toBeFalsy();
        expect(rule.match(new Request('http://example.org/wp-admin/wp-login.php'))).toBeTruthy();
        expect(rule.match(new Request('http://example.org/wp-admin/wp-admin/js/password-strength-meter.min.js'))).toBeFalsy();
    });

    it('Testing New Rule 3', () => {
        const rule = firewall.createRule(`

(http.request.uri.path contains "/wp-login.php") or (http.request.uri.path contains "/wp-admin/" and not http.request.uri.path in {"/wp-admin/admin-ajax.php" "/wp-admin/js/password-strength-meter.min.js"})
        `);

        expect(rule.match(new Request('http://example.org/wp-admin/'))).toBeTruthy();
        expect(rule.match(new Request('http://example.org/wp-admin/admin-ajax.php'))).toBeFalsy();
        expect(rule.match(new Request('http://example.org/wp-admin/wp-login.php'))).toBeTruthy();
        expect(rule.match(new Request('http://example.org/wp-admin/wp-admin/js/password-strength-meter.min.js'))).toBeFalsy();
    });

});
```