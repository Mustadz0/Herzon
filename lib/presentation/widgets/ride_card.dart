import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/models/ride_model.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onTap;

  const RideCard({super.key, required this.ride, this.onTap});

  String get _formattedDeparture =>
      '${ride.departureTime.day.toString().padLeft(2, '0')}/${ride.departureTime.month.toString().padLeft(2, '0')} '
      '${ride.departureTime.hour.toString().padLeft(2, '0')}:${ride.departureTime.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.originName,
                          style: context.theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.destinationName,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ride.seatsAvailable > 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ride.seatsAvailable > 0 ? '${ride.seatsAvailable} seats' : 'Full',
                      style: context.theme.textTheme.labelSmall?.copyWith(
                        color: ride.seatsAvailable > 0 ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    _formattedDeparture,
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle_rounded, size: 20, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Driver',
                        style: context.theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${ride.pricePerSeat.toStringAsFixed(2)}',
                    style: context.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
