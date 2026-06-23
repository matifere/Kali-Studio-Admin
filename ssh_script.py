import pexpect
import sys

child = pexpect.spawn('ssh -o StrictHostKeyChecking=no mati@192.168.0.41', encoding='utf-8')
child.expect('password:')
child.sendline('2102')
child.expect(r'\$ |# ')
child.sendline('sudo -S docker ps')
child.expect(r'\[sudo\] password for mati:')
child.sendline('2102')
child.expect(r'\$ |# ')
print(child.before)
child.sendline('sudo docker inspect $(sudo docker ps -q) | grep -i "POSTGRES\\|MYSQL\\|MONGO"')
child.expect(r'\$ |# ')
print(child.before)
child.sendline('ls -la /opt /home/mati')
child.expect(r'\$ |# ')
print(child.before)
child.sendline('exit')
