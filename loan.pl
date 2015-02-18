#!/usr/bin/perl -w
use strict;

use POSIX qw(ceil);

my @information;

print "Hello, welcome to the loan calculator.\n";
while (1) {
	print "What would you like to calculate?\n(l)oan payment\n(n)umber of payments remaining\n(a)mortization schedule\n(q)uit?\n> ";
	my $user_command = <STDIN>;
	chomp $user_command;
	$user_command = lc($user_command);

	@information = gather_information($user_command);
	
	print "\n";
	($user_command eq 'l') ? printf "Your monthly payment is \$%.2f\n\n", payment_calc()
						: ($user_command eq 'n') ? print "Number of payments left: ", nper_calc(), "\n\n"
						: ($user_command eq 'a') ? amort_schedule()
						: ($user_command eq 'q') ? exit
						: print "Couldn't figure out what you were looking for\n";
	print "\n";
}



sub gather_information {
	my ($pv, $int_rate, $nper, $pmt);
	if ($_[0] eq 'l' || $_[0] eq 'n' || $_[0] eq 'a') {   
		print "Loan balance (ie. \$50,500.50 = 50500.50)? ";
		$pv = <STDIN>;
		chomp $pv;
	}
	
	if ($_[0] eq 'l' || $_[0] eq 'n' || $_[0] eq 'a') {
		print "Interest rate (ie 5.25% = 5.25)? ";
		$int_rate = <STDIN>;
		chomp $int_rate;
	}
	
	if ($_[0] eq 'l' || $_[0] eq 'a') {
		print "Loan term in months (ie. 30 year loan = 360)? ";
		$nper = <STDIN>;
		chomp $nper;
	}
	
	if ($_[0] eq 'n') {
		print "What is the monthly payment (ie. \$800.25 = 800.25)? ";
		$pmt = <STDIN>;
		chomp $pmt;
	}
	
	return $pv, $int_rate, $nper, $pmt;
}

sub payment_calc {
	my $information_ref = \@information;
	my ($pv, $int_rate, $nper, $pmt) = @{$information_ref};
	$int_rate /= (100 * 12);
	my $payment = ($int_rate * $pv) / (1 - (1 + $int_rate) ** (-1 * $nper));
	return $payment;
}

sub nper_calc {
	my $information_ref = \@information;
	my ($pv, $int_rate, $nper, $pmt) = @{$information_ref};
	$int_rate /= 100;
	$nper = (log($pmt) - log($pmt - ($pv * $int_rate / 12))) / log(1 + $int_rate / 12);
	$nper = ceil($nper);		#last payment is still a payment even if it is reduced (typically within a few dollars of the regular payment).
	return $nper;
}

sub amort_schedule {
	my $information_ref = \@information;
	my ($pv, $int_rate, $nper, $pmt) = @{$information_ref};
	$pmt = round_to_the_nearest_penny(payment_calc(@information));
	my $running_balance = $pv;  #$month_number != $nper+1
	for (my $month_number = 1; $month_number <= 360; $month_number++) {
		my $int_expense = round_to_the_nearest_penny($running_balance * $int_rate / (100 *12));
		$pmt = ($running_balance + $int_expense) if ($pmt > ($running_balance + $int_expense));
		last if ($pmt == 0);

		print "Month \#$month_number\n";
		printf "\tBeg Balance:\t\$%.2f\n", $running_balance;
		printf "\tPayment:\t\$%.2f\n", $pmt;
		printf "\tInt Expense:\t\$%.2f\n", $int_expense;
		
		$running_balance = $running_balance - $pmt + $int_expense;
		if ($running_balance <= 0.001){
			print "\tEnding Balance:\t\$0.00\n\n";
		}
		else {
			printf "\tEnding Balance:\t\$%.2f\n\n", $running_balance;
		}
		
		if ($running_balance =~ /(\d+\.*\d{0,2})/) {$running_balance = $1;}
	}
	print "\n";
}

sub round_to_the_nearest_penny {
	my ($dollars, $cents);

	if ($_[0] =~ /\./) {
		$_[0] =~ /(\d+)\.(\d{0,2})/;
		$dollars = $1;
		$cents = $2;
		$cents *= 10 unless $cents =~ /\d\d/;
	}
	else {
		$dollars = $_[0];
		$cents = 0;
	}
	if ($_[0] =~ /\.\d\d(\d)/) {
		$cents++ if $1 >= 5;
	}
	return $dollars + $cents/100;
}