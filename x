#!/usr/bin/env perl
use strict;

my $hosts = '/etc/hosts';
my $groupName = join ' ', @ARGV;

# 检查参数个数，如果不为1则提示并退出
if ($groupName eq '') {
  print "请输入组的名字。\n";
  exit 0;
}

# 查找是否存在要切换的组
my @groups = `grep -hn "^#====\\s\\{0,\\}$groupName\\s*\$" $hosts`;
if (!defined(@groups[-1])) {
  print "没有找到组 \"$groupName\" 。\n";

  my @nowGroups = `grep "^#====\\s\\{0,\\}\\S" $hosts`;
  if (scalar @nowGroups > 0) {
    print "现有如下组：\n";
    foreach (@nowGroups) {
      $_ =~ s/^#====\s+//;
      print $_;
    }
  }
  exit 0;
}

# 提取最后一个匹配的组的行号
my $lineNumber;
if ($groups[-1] =~ /^(\d+):/) {
  $lineNumber = $1;
}

# 读取hosts文件内容
my @lines = `cat $hosts`;
foreach ($lineNumber..$#lines) {
  # $host表示一整行
  my $host = @lines[$_];

  # 如果遇到#====则认为该组已经完成
  if ($host =~ /^\s*#====/) {
    last;
  }

  # 提取域名，并注释掉该域名对应的其他生效的IP
  $host =~ /\s+(\S+)$/;
  my $domain = $1;
  foreach (0..$#lines) {
    if (@lines[$_] =~ /^\s*\d.+($domain)$/) {
      @lines[$_] =~ s/^(\s*)/#/;
    }
  }
  
  $lines[$_] =~ s/^\s*#+\s*//;
}

# 写入文件
open (F, ">$hosts") or die "打开hosts文件失败";
print F @lines;
close F;

# 清除DNS缓存
my $dnsCheckResult = `ps aux | grep "^_mdnsresponder"`;
if ($dnsCheckResult) {
  `sudo killall mDNSResponder`;
}
